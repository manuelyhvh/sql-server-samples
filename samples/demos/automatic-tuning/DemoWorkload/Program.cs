using System;
using System.Configuration;
using System.Windows.Forms;
using System.Globalization;

namespace DemoWorkload
{
    static class Program
    {
        public static int THREAD_COUNT = int.Parse(ConfigurationManager.AppSettings["ThreadCount"], CultureInfo.InvariantCulture);
        public static int REQUEST_COUNT = int.Parse(ConfigurationManager.AppSettings["RequestCount"], CultureInfo.InvariantCulture);
        public static int ROW_COUNT = int.Parse(ConfigurationManager.AppSettings["RowCount"], CultureInfo.InvariantCulture);
        public static int TRANSACTION_COUNT = int.Parse(ConfigurationManager.AppSettings["TransactionCount"], CultureInfo.InvariantCulture);
        public static long MAX_TPS = int.Parse(ConfigurationManager.AppSettings["MaxTps"], CultureInfo.InvariantCulture);
        public static long MAX_PageRead = int.Parse(ConfigurationManager.AppSettings["MaxPageReads"], CultureInfo.InvariantCulture);
        public static string CONN_STR = ConfigurationManager.ConnectionStrings["WideWorldImporters"].ConnectionString;

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new FrmMain());
        }
    }
}
