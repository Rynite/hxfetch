package;

import haxe.macro.Expr;

class BuildFunction {
    macro static public function build():Expr{
        // print right
        var pr = macro function print_fetch(distro:String) {

           trace("hello");
           
        }

    }
}