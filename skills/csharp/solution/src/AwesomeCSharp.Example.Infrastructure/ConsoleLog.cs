using System;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Infrastructure;

public class ConsoleLog<T> : ILog<T>
{
    public void Info(string message)
    {
        Write("INFO", message);
    }

    public void Warn(string message)
    {
        Write("WARN", message);
    }

    public void Error(string message, Exception exception)
    {
        Write("ERROR", $"{message} {exception}");
    }

    private static void Write(string level, string message)
    {
        Console.WriteLine($"{DateTime.UtcNow:O} {level} {typeof(T).Name} {message}");
    }
}
