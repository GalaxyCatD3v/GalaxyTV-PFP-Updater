using System;
using GalaxyLabs.JellyFin.Plugin.GalaxyTV_PFP_Updater.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Controller.Plugins;
using MediaBrowser.Model.Serialization;

namespace GalaxyLabs.JellyFin.Plugin.GalaxyTV_PFP_Updater
{
    public class Plugin : BasePlugin<PluginConfiguration>, IHasEmbeddedImage
    {
        public static Plugin? Instance { get; private set; }

        public override string Name => "GalaxyTV PFP Updater";
        public override Guid Id => Guid.Parse("8f3e2a1b-4c5d-6e7f-8a9b-0c1d2e3f4a5b");
        public override string Description => "Fetches user profile pictures from an external API and updates Jellyfin users.";

        public string ImageResourceName => $"{GetType().Namespace}.thumb.png";

        public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
            : base(applicationPaths, xmlSerializer)
        {
            Instance = this;
        }
    }
}