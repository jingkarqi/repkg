using System;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;
using RePKG.Command;
using RePKG.Gui.Localization;

namespace RePKG.Gui
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            OutputTextBox.Text = Environment.CurrentDirectory;
            SelectLanguageForCurrentCulture();
        }

        private void SelectLanguageForCurrentCulture()
        {
            var culture = CultureInfo.CurrentUICulture.Name;
            foreach (var item in LanguageCombo.Items)
            {
                if (item is ComboBoxItem combo && combo.Tag is string tag && tag.Equals(culture, StringComparison.OrdinalIgnoreCase))
                {
                    LanguageCombo.SelectedItem = combo;
                    return;
                }
            }

            LanguageCombo.SelectedIndex = 0;
        }

        private void LanguageCombo_OnSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (LanguageCombo.SelectedItem is ComboBoxItem item && item.Tag is string culture)
            {
                LocalizationManager.ChangeCulture(culture);
            }
        }

        private void BrowseInput_OnClick(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Title = Localize("SelectInputTitle"),
                Filter = "PKG/TEX (*.pkg;*.tex)|*.pkg;*.tex|All files (*.*)|*.*"
            };

            if (dialog.ShowDialog(this) == true)
            {
                InputTextBox.Text = dialog.FileName;
            }
        }

        private void BrowseOutput_OnClick(object sender, RoutedEventArgs e)
        {
            using (var dialog = new System.Windows.Forms.FolderBrowserDialog())
            {
                dialog.Description = Localize("SelectOutputTitle");
                dialog.SelectedPath = OutputTextBox.Text;

                if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                {
                    OutputTextBox.Text = dialog.SelectedPath;
                }
            }
        }

        private async void Extract_OnClick(object sender, RoutedEventArgs e)
        {
            LogTextBox.Clear();
            SetBusy(true);

            try
            {
                var options = new ExtractOptions
                {
                    Input = InputTextBox.Text,
                    OutputDirectory = OutputTextBox.Text,
                    Recursive = RecursiveCheckBox.IsChecked == true,
                    TexDirectory = TexDirCheckBox.IsChecked == true,
                    Overwrite = OverwriteCheckBox.IsChecked == true
                };

                await RunWithConsoleCapture(() => Extract.Action(options));
                MessageBox.Show(this, Localize("DoneMessage"), Localize("AppTitle"), MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                AppendLog(ex.ToString());
                MessageBox.Show(this, Localize("ErrorMessage"), Localize("AppTitle"), MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                SetBusy(false);
            }
        }

        private async void Info_OnClick(object sender, RoutedEventArgs e)
        {
            LogTextBox.Clear();
            SetBusy(true);

            try
            {
                var options = new InfoOptions
                {
                    Input = InputTextBox.Text,
                    TexDirectory = TexDirCheckBox.IsChecked == true,
                    PrintEntries = true
                };

                await RunWithConsoleCapture(() => Info.Action(options));
            }
            catch (Exception ex)
            {
                AppendLog(ex.ToString());
                MessageBox.Show(this, Localize("ErrorMessage"), Localize("AppTitle"), MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                SetBusy(false);
            }
        }

        private async Task RunWithConsoleCapture(Action action)
        {
            var sb = new StringBuilder();
            var originalOut = Console.Out;
            var originalErr = Console.Error;

            using (var writer = new StringWriter(sb))
            {
                try
                {
                    Console.SetOut(writer);
                    Console.SetError(writer);
                    await Task.Run(action);
                }
                finally
                {
                    Console.SetOut(originalOut);
                    Console.SetError(originalErr);
                }
            }

            AppendLog(sb.ToString());
        }

        private void AppendLog(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return;

            Dispatcher.Invoke(() =>
            {
                LogTextBox.AppendText(text);
                if (!text.EndsWith(Environment.NewLine))
                    LogTextBox.AppendText(Environment.NewLine);
                LogTextBox.ScrollToEnd();
            });
        }

        private void SetBusy(bool busy)
        {
            ExtractButton.IsEnabled = !busy;
            InfoButton.IsEnabled = !busy;
        }

        private string Localize(string key)
        {
            var value = System.Windows.Application.Current.Resources[key];
            return value?.ToString() ?? key;
        }
    }
}
