structure Eces = struct

exception Fatal of string
exception Fail

exception NoArgs

fun println s = print (s ^ "\n");

fun usage _ = app println
		  [ "usage:",
		    "\teces command arguments...",
		    "",
		    "commands:",
		    "",
		    "\tload",
		    ""
		  ]
		  
fun load nil = raise Fatal "load: need 1 or more arguments"
  | load _ = raise Fatal "load: not implemented yet"

fun main (prog, args) =
  (let
      fun parseArgs nil = (usage(); raise NoArgs)
	| parseArgs ("help" :: _) = usage
	| parseArgs ("load" :: _) = load
	| parseArgs (name :: _) = raise Fatal ("unknown command: " ^ name)

      val cmd = parseArgs args handle NoArgs => raise Fail
  in
      cmd (tl args);
      OS.Process.success
  end)
  handle Fatal msg => (println msg; OS.Process.failure)
       | Fail => OS.Process.failure

end

val _ = OS.Process.exit (Eces.main (CommandLine.name(), CommandLine.arguments()))
