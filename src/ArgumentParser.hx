package;

import hxargs.Args;

class ArgumentParser {

    public static var color1 = "";
    public static var color2 = "";

    public static function register() {
        var argHandler = hxargs.Args.generate([
			@doc("Set color1")
			["-c1", "--color1"] => function(c:String) color1 = c,

            @doc("Set color2")
            ["-c2", "--color2"] => function(c:String) color2 = c,

            _ => function(arg:String) trace ("Unknown command: " +arg)
		
		]);
		
		var args = Sys.args();
		
        argHandler.parse(args);

        if (color1 == "") {
            color1 = "white";
        } else if (color2 == "") {
            color2 = "white";
        }
    }
}