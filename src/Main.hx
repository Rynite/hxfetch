package;

import hxargs.Args;

class Main {
	static function main() {
		var color1 = hxargs.Args.generate([
			@doc("Documentation for your command")
			["-cmd", "--alternative-command"] => function(arg:String) {
				trace("For changing color1");
			},
		
			_ => function(arg:String) {
				// trace("does this work");
			}
		]);
		
		var args = Sys.args();
		
		if (args.length == 0) {
			Sys.println(color1.getDoc());
		}
	
		else color1.parse(args);

		HxFetch.print_fetch("archlinux");
	}
}
