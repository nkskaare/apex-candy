Logger.StackTrace stack = new Logger.StackTrace(new DmlException());

System.debug(stack.traceString);