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

val homeDir = valOf (Posix.ProcEnv.getenv "HOME") handle Option.Option => raise Fatal "could not get home directory"

val root = OS.Path.concat (homeDir, ".eces") handle OS.Path.Path => raise Fatal ("concat " ^ homeDir ^ " " ^ ".eces")

fun exec cmd args =
  case (Posix.Process.fork () handle e as OS.SysErr (_, _) => raise Fatal ("exec " ^ cmd ^ " " ^ (foldl (fn (x, acc) => acc ^ x ^ " ") "" args) ^ exnMessage e)) of
      NONE => ignore (Posix.Process.execp (cmd, (cmd::args)))
   |  SOME pid => ignore (Posix.Process.waitpid (Posix.Process.W_CHILD pid, nil))

fun fetch name uri =
  let
      val target = OS.Path.concat (root, name)
		   handle OS.Path.Path => raise Fatal ("concat " ^ root ^ " " ^ name)
  in
      ignore (exec "git" ["clone", uri, target])
      handle e as OS.SysErr (msg, err) => raise Fatal ("fetch " ^ uri ^ " " ^ target ^ ": " ^ (exnMessage e))
  end

fun exist file = Posix.FileSys.access (file, []);

fun isInstalled dir =
  if not (exist dir) then
      false
  else
      OS.FileSys.isDir dir handle e as OS.SysErr (msg, err) => raise Fatal ("checking installed (" ^ dir ^ "): " ^ (exnMessage e))

fun ensureRemoved dir = if not (exist dir) then () else
			let
			    val _ = if Posix.FileSys.access (dir, [Posix.FileSys.A_WRITE]) then () else raise Fatal (dir ^ " is not writable")
			    val _ = if OS.FileSys.isDir dir then () else raise Fatal (dir ^ " is not directory")
			    val _ = if OS.FileSys.isLink dir then () else raise Fatal ("error: could not remove .emacs.d because " ^ dir ^ " already exists")
			in
			    Posix.FileSys.unlink dir
			end

fun load' name uri =
  let
      val dir = OS.Path.concat (root, name) handle OS.Path.Path => raise Fatal ("fatal: concat " ^ root ^ " " ^ name)

      val () = if not (isInstalled dir) then fetch name uri else ()

      val target = OS.Path.concat (homeDir, ".emacs.d") handle OS.Path.Path => raise Fatal ("fatal: concat " ^ homeDir ^ " " ^ ".emacs.d")

      val () = ensureRemoved target
  in
      Posix.FileSys.symlink {old = dir, new = target}
  end

fun load (name :: uri :: nil) = load' name uri
  | load _ = raise Fatal "load: need just 2 arguments"

fun main args =
  let
      fun getCmd nil = (usage (); raise NoArgs)
	| getCmd ("help" :: _) = usage
	| getCmd ("load" :: _) = load
	| getCmd (name :: _) = raise Fatal ("unknown command: " ^ name)

      val cmd = getCmd args handle NoArgs => raise Fail
  in
      cmd (tl args);
      OS.Process.success
  end
  handle Fatal msg => (println msg; OS.Process.failure)
       | Fail => OS.Process.failure

end

val _ = OS.Process.exit (Eces.main (CommandLine.arguments ()))
