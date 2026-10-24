using System;

namespace AwesomeCSharp.Example.Core;

public interface ILog<T>
{
    void Info(string message);

    void Warn(string message);

    void Error(string message, Exception exception);
}
