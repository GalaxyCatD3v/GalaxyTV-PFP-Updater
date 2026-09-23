using MediaBrowser.Model.Plugins;

namespace GalaxyLabs.JellyFin.Plugin.GalaxyTV_PFP_Updater.Configuration
{
    public class PluginConfiguration : BasePluginConfiguration
    {
        public string ApiUrl { get; set; } = "https://slashask.galaxylabs.ca/avatars/?jellyfin_username={0}";
    }
}