using System;
using System.Globalization;
using System.Linq;
using System.Windows;

namespace RePKG.Gui.Localization
{
    public static class LocalizationManager
    {
        private static readonly string[] SupportedCultures = { "en-US", "zh-CN" };

        public static void ChangeCulture(string cultureName)
        {
            if (string.IsNullOrWhiteSpace(cultureName) || !SupportedCultures.Contains(cultureName))
                cultureName = "en-US";

            var culture = new CultureInfo(cultureName);
            CultureInfo.CurrentUICulture = culture;
            CultureInfo.CurrentCulture = culture;

            ResourceDictionary newDictionary;
            try
            {
                newDictionary = new ResourceDictionary
                {
                    Source = new Uri($"Localization/Strings.{cultureName}.xaml", UriKind.Relative)
                };
            }
            catch
            {
                newDictionary = new ResourceDictionary
                {
                    Source = new Uri("Localization/Strings.en-US.xaml", UriKind.Relative)
                };
            }

            var dictionaries = System.Windows.Application.Current.Resources.MergedDictionaries;
            var oldDictionary = dictionaries.FirstOrDefault(d =>
                d.Source != null && d.Source.OriginalString.StartsWith("Localization/Strings.", StringComparison.OrdinalIgnoreCase));

            if (oldDictionary != null)
                dictionaries.Remove(oldDictionary);

            dictionaries.Add(newDictionary);
        }
    }
}
