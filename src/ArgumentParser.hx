package;

import hxargs.Args;

class ArgumentParser {

    public static var color1:String = "";
    public static var color2:String = "";
    public static var layout:String = "";
    public static var border:String = "";

    public static function register() {
        var argHandler = hxargs.Args.generate([
			@doc("Set color1")
			["-c1", "--color1"] => function(c:String) color1 = c,

            @doc("Set color2")
            ["-c2", "--color2"] => function(c:String) color2 = c,
            
            @doc("Set the layout of the fetch details")
            ["-l", "--layout"] => function (l:String) layout = l,

            @doc("If you want a border or not around your fetch details")
            ["-b", "--border"] => function (b:String) border = b,

            _ => function(arg:String) trace ("Unknown command: " +arg)
		
		]);
		
		var args = Sys.args();
		
        argHandler.parse(args);

        if (color1 == "" && HxFetch.config.color1 == "") {
            color1 = "white";
        }
        if (color2 == "" && HxFetch.config.color2 == "") {
            color2 = "white";
        }
        if (layout == "" && HxFetch.config.layout == "") {
            layout = "right";
        }
        if (border == "" && HxFetch.config.border == "") {
            border = "white";
        }
    }
}