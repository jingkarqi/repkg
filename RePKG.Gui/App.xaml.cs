using System.Globalization;
using System.Windows;
using RePKG.Gui.Localization;

namespace RePKG.Gui
{
    public partial class App : System.Windows.Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            LocalizationManager.ChangeCulture(CultureInfo.CurrentUICulture.Name);
        }
    }
}
