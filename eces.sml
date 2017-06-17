infixr 0 $
fun f $ x = f x

infixr 9 o

structure Eces = struct

exception Fatal of string
exception Fail

exception NoArgs

fun println s = print $ s ^ "\n"

fun usage _ = app println
		  [ "Eces is a tool for switching settings of Emacs.",
		    "",
		    "usage:",
		    "\teces command arguments...",
		    "",
		    "commands:",
		    "",
		    "\thelp       print this help",
		    "\tinstall    fetch repository of .emacs.d",
		    "\tlist       list repositories",
		    "\tswitch     switch .emacs.d",
		    "\tupdate     update .emacs.d",
		    ""
		  ]

val homeDir = valOf $ Posix.ProcEnv.getenv "HOME" handle Option.Option => raise Fatal "could not get home directory"

val root = OS.Path.concat (homeDir, ".eces") handle OS.Path.Path => raise Fatal ("concat " ^ homeDir ^ " " ^ ".eces")

fun exec cmd args =
  case (Posix.Process.fork () handle e as OS.SysErr (_, _) => raise Fatal ("exec " ^ cmd ^ " " ^ (foldl (fn (x, acc) => acc ^ x ^ " ") "" args) ^ exnMessage e)) of
      NONE => ignore $ Posix.Process.execp (cmd, cmd::args)
   |  SOME pid => ignore $ Posix.Process.waitpid (Posix.Process.W_CHILD pid, nil)

fun fetch name uri =
  let
      val target = OS.Path.concat (root, name)
		   handle OS.Path.Path => raise Fatal ("concat " ^ root ^ " " ^ name)
  in
      ignore $ exec "git" ["clone", uri, target]
      handle e as OS.SysErr (msg, err) => raise Fatal ("fetch " ^ uri ^ " " ^ target ^ ": " ^ (exnMessage e))
  end

fun exist file = Posix.FileSys.access (file, []);

fun isInstalled dir =
  if not $ exist dir then
      false
  else
      OS.FileSys.isDir dir handle e as OS.SysErr (msg, err) => raise Fatal ("checking installed (" ^ dir ^ "): " ^ (exnMessage e))

fun ensureRemoved dir = if not $ exist dir then () else
			let
			    val _ = if Posix.FileSys.access (dir, [Posix.FileSys.A_WRITE]) then () else raise Fatal (dir ^ " is not writable")
			    val _ = if OS.FileSys.isDir dir then () else raise Fatal (dir ^ " is not directory")
			    val _ = if OS.FileSys.isLink dir then () else raise Fatal ("error: could not remove .emacs.d because " ^ dir ^ " already exists")
			in
			    Posix.FileSys.unlink dir
			end

fun install' name uri =
  let
      val dir = OS.Path.concat (root, name) handle OS.Path.Path => raise Fatal ("fatal: concat " ^ root ^ " " ^ name)
  in
      if not $ isInstalled dir then
	  fetch name uri
      else
	  ()
  end

fun install (name :: uri :: nil) = install' name uri
  | install _ = raise Fatal "install: need just 2 arguments"

fun update (name :: nil) =
  let
      val dir = OS.Path.concat (root, name)
      val existDir = exist dir handle OS.Path.Path => raise Fatal ("error: concat " ^ root ^ " " ^ name)
  in
      if existDir then
	  exec "git" ["-C", dir, "pull"]
      else
	  raise Fatal ("no directory: " ^ dir)
  end
  | update _ = raise Fatal "need just 1 argument"

fun switch (name :: nil) =
  let
      val dir = OS.Path.concat (root, name) handle OS.Path.Path => raise Fatal ("fatal: concat " ^ root ^ " " ^ name)

      val target = OS.Path.concat (homeDir, ".emacs.d") handle OS.Path.Path => raise Fatal ("fatal: concat " ^ homeDir ^ " " ^ ".emacs.d")

      val () = ensureRemoved target
  in
      Posix.FileSys.symlink {old = dir, new = target}
  end
  | switch _ = raise Fatal "need just 1 argument"

fun listFiles' stream list =
  case OS.FileSys.readDir stream of
      NONE => list
    | SOME name => listFiles' stream $ name :: list

fun listFiles dir =
  let
      val stream = OS.FileSys.openDir dir

      val list = listFiles' stream []
  in
      OS.FileSys.closeDir stream;
      list
  end
  handle e as OS.SysErr (_, _) => []

fun list nil = app println o rev o listFiles $ root
  | list _ = raise Fatal "no arguments needed"

fun main args =
  let
      fun getCmd nil = (usage (); raise NoArgs)
	| getCmd ("help" :: _) = usage
	| getCmd ("install" :: _) = install
	| getCmd ("list" :: _) = list
	| getCmd ("switch" :: _) = switch
	| getCmd ("update" ::_) = update
	| getCmd (name :: _) = raise Fatal ("unknown command: " ^ name)

      val cmd = getCmd args handle NoArgs => raise Fail
  in
      cmd $ tl args;
      OS.Process.success
  end
  handle Fatal msg => (println msg; OS.Process.failure)
       | Fail => OS.Process.failure

end

val _ = OS.Process.exit o Eces.main $ CommandLine.arguments ()
