using System.Diagnostics;
using System.IO;

namespace OneyNES
{
    class Program
    {
        static void Main(string[] args)
        {
            Process p = new Process();
            p.StartInfo.WorkingDirectory = Directory.GetCurrentDirectory();
            p.StartInfo.FileName = "compile.bat";
            p.Start();
            p.WaitForExit();
        }
    }
}
