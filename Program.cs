using System.Diagnostics;

if (args.Length == 0 || args[0] == "--help" || args[0] == "-h")
{
    Console.Error.WriteLine("Usage: lazygit-custom-pager-wrapper <path> <old> <unused> <unused> <new>");
    Console.Error.WriteLine("Example: lazygit-custom-pager-wrapper path old x x new");
    return 1;
}

if (args.Length < 5)
{
    Console.Error.WriteLine("Error: Expected at least 5 arguments");
    Console.Error.WriteLine("Usage: lazygit-custom-pager-wrapper <path> <old> <unused> <unused> <new>");
    return 1;
}

ReadOnlySpan<char> mergedPath = args[0];
ReadOnlySpan<char> localPathArg = args[1];
ReadOnlySpan<char> remotePathArg = args[4];

Span<char> localPathBuffer = stackalloc char[localPathArg.Length];
localPathArg.Replace(localPathBuffer, '\\', '/');
ReadOnlySpan<char> localPath = localPathBuffer;

Span<char> remotePathBuffer = stackalloc char[remotePathArg.Length];
remotePathArg.Replace(remotePathBuffer, '\\', '/');
ReadOnlySpan<char> remotePath = remotePathBuffer;

// Start git diff process
var gitProcess = new Process
                 {
                     StartInfo = new ProcessStartInfo
                                 {
                                     FileName = "git",
                                     Arguments = $"diff --no-index --no-ext-diff \"{localPath}\" \"{remotePath}\"",
                                     RedirectStandardOutput = true,
                                     RedirectStandardError = false,
                                     UseShellExecute = false
                                 }
                 };

gitProcess.Start();
Span<char> lineBuffer = stackalloc char[2 * 1024];

// Process each line: replace local and remote paths with the merged path
while (gitProcess.StandardOutput.ReadLine() is { } lineString)
{
    if (lineString.Length > lineBuffer.Length)
    {
        // no replacements needed, just write the line as is, or
        // the line is too long to fit in the buffer, so write it directly
        Console.WriteLine(lineString);
    }
    else if (!string.IsNullOrEmpty(lineString))
    {
        // we want the equivalent of
        //
        //     line.Replace(oldValue:localPath, newValue: mergedPath)
        //         .Replace(oldValue:remotePath, newValue: mergedPath)
        //
        // but we know that only one of either localPath or remotePath can be present, and only once,
        // so we can do it in one pass.

        ReadOnlySpan<char> line = lineString;
        int localPathIndex = line.IndexOf(localPath);
        int newLength;

        if (localPathIndex >= 0)
        {
            // replace localPath with mergedPath
            line[..localPathIndex].CopyTo(lineBuffer);
            mergedPath.CopyTo(lineBuffer.Slice(localPathIndex, mergedPath.Length));
            line[(localPathIndex + localPath.Length)..].CopyTo(lineBuffer[(localPathIndex + mergedPath.Length)..]);
            newLength = lineString.Length + (mergedPath.Length - localPath.Length);
        }
        else
        {
            int remotePathIndex = line.IndexOf(remotePath);

            if (remotePathIndex >= 0)
            {
                // replace remotePath with mergedPath
                line[..remotePathIndex].CopyTo(lineBuffer);
                mergedPath.CopyTo(lineBuffer.Slice(remotePathIndex, mergedPath.Length));
                line[(remotePathIndex + remotePath.Length)..].CopyTo(lineBuffer[(remotePathIndex + mergedPath.Length)..]);
                newLength = lineString.Length + (mergedPath.Length - remotePath.Length);
            }
            else
            {
                // No path found, just write original
                Console.WriteLine(lineString);
                continue;
            }
        }

        Console.WriteLine(lineBuffer[..newLength]);
    }
}

// Wait for git process to finish
gitProcess.WaitForExit();

return 0;
