using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using GalaxyLabs.JellyFin.Plugin.GalaxyTV_PFP_Updater.Configuration;
using Jellyfin.Database.Implementations.Entities;
using MediaBrowser.Controller.Configuration;
using MediaBrowser.Controller.Library;
using MediaBrowser.Model.Tasks;
using Microsoft.Extensions.Logging;

namespace GalaxyLabs.JellyFin.Plugin.GalaxyTV_PFP_Updater.ScheduledTasks
{
    public class UpdateProfilePicturesTask : IScheduledTask
    {
        private readonly IUserManager _userManager;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IServerConfigurationManager _serverConfigurationManager;
        private readonly ILogger<UpdateProfilePicturesTask> _logger;

        public UpdateProfilePicturesTask(
            IUserManager userManager,
            IHttpClientFactory httpClientFactory,
            IServerConfigurationManager serverConfigurationManager,
            ILogger<UpdateProfilePicturesTask> logger)
        {
            _userManager = userManager;
            _httpClientFactory = httpClientFactory;
            _serverConfigurationManager = serverConfigurationManager;
            _logger = logger;
        }

        public string Name => "Update User Profile Pictures";
        public string Key => "UserProfilePictureUpdaterTask";
        public string Description => "Fetches profile pictures from external API and updates Jellyfin users.";
        public string Category => "Maintenance";

        public async Task ExecuteAsync(IProgress<double> progress, CancellationToken cancellationToken)
        {
            var users = _userManager.GetUsers();
            int total = users.Count();
            int processed = 0;

            var config = Plugin.Instance?.Configuration;
            string apiUrlTemplate = config?.ApiUrl ?? "https://slashask.galaxylabs.ca/avatars/?jellyfin_username={0}";

            using var httpClient = _httpClientFactory.CreateClient();

            foreach (var user in users)
            {
                cancellationToken.ThrowIfCancellationRequested();

                var username = user.Username;
                if (string.IsNullOrEmpty(username))
                {
                    _logger.LogWarning("User {UserId} has no username, skipping.", user.Id);
                    processed++;
                    progress.Report((double)processed / total * 100);
                    continue;
                }

                string url = string.Format(apiUrlTemplate, Uri.EscapeDataString(username));
                _logger.LogDebug("Fetching profile picture for user {Username} from {Url}", username, url);

                try
                {
                    var response = await httpClient.GetAsync(url, cancellationToken).ConfigureAwait(false);

                    if (response.IsSuccessStatusCode)
                    {
                        var contentType = response.Content.Headers.ContentType?.MediaType;
                        if (contentType != null && contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
                        {
                            byte[] imageBytes = await response.Content.ReadAsByteArrayAsync(cancellationToken).ConfigureAwait(false);
                            await SetProfileImageAsync(user, imageBytes, contentType, cancellationToken).ConfigureAwait(false);
                            _logger.LogInformation("Updated profile picture for user {Username}", username);
                        }
                        else
                        {
                            _logger.LogWarning("API returned non-image content for user {Username} (content type: {ContentType}), skipping update.", username, contentType ?? "null");
                        }
                    }
                    else if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                    {
                        _logger.LogInformation("No profile picture found for user {Username} (404), skipping update.", username);
                    }
                    else
                    {
                        _logger.LogWarning("Unexpected status {StatusCode} for user {Username}, skipping update.", response.StatusCode, username);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error fetching profile picture for user {Username}, skipping update.", username);
                }

                processed++;
                progress.Report((double)processed / total * 100);
            }

            progress.Report(100);
        }

        public IEnumerable<TaskTriggerInfo> GetDefaultTriggers()
        {
            yield return new TaskTriggerInfo
            {
                IntervalTicks = TimeSpan.FromHours(24).Ticks,
                Type = TaskTriggerInfoType.IntervalTrigger
            };
        }

        private async Task SetProfileImageAsync(User user, byte[] imageBytes, string contentType, CancellationToken cancellationToken)
        {
            if (!TryGetImageExtension(contentType, out var extension))
            {
                throw new InvalidOperationException($"Unsupported content type: {contentType}");
            }

            var userDataPath = Path.Combine(
                _serverConfigurationManager.ApplicationPaths.UserConfigurationDirectoryPath,
                user.Username);

            Directory.CreateDirectory(userDataPath);

            if (user.ProfileImage is not null)
            {
                await _userManager.ClearProfileImageAsync(user).ConfigureAwait(false);
            }

            var imagePath = Path.Combine(userDataPath, "profile" + extension);
            await File.WriteAllBytesAsync(imagePath, imageBytes, cancellationToken).ConfigureAwait(false);

            user.ProfileImage = new ImageInfo(imagePath);
            await _userManager.UpdateUserAsync(user).ConfigureAwait(false);
        }

        private static bool TryGetImageExtension(string? contentType, out string extension)
        {
            extension = contentType?.Split(';')[0].Trim().ToLowerInvariant() switch
            {
                "image/jpeg" => ".jpg",
                "image/png" => ".png",
                "image/gif" => ".gif",
                "image/webp" => ".webp",
                "image/bmp" => ".bmp",
                _ => string.Empty
            };

            return extension.Length > 0;
        }
    }
}