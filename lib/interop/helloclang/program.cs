using System;
using System.Runtime.InteropServices;

public class Program
{
    // Import the function from the shared object using P/Invoke
    [DllImport("hello.so")]
    public static extern int sum(int a, int b);

    public static void Main()
    {
        int result = sum(2, 3);
        Console.WriteLine("The result is: " + result);
    }
}