# simple_trace_rb

Dead-simple tracing. Logs to the [Trace Event Format](https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/preview?tab=t.0#heading=h.yr4qxyxotyw) which is compatible with [chrome's devtools](https://www.chromium.org/developers/how-tos/trace-event-profiling-tool/) and also with [speedscope.app](https://www.speedscope.app). Essentially, APM that never leaves your filesystem.

Because it is such a thin wrapper, I do not distribute it as a library. There are so many ways in which someone could want this code to function differently, so rather than build the omni-solution, I've built the barebones app that you can customize (hopefully with minimal effort) to your use-case.

If you would like to use it, feel free to copy it into your app and make whatever changes you think make sense for your setup.
