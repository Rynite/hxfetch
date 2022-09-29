import DFParser.DfParser;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;

using StringTools;

// This class won't be neofetch dependent, it'll essentially use coreutilss
class HxFetch {

    public static var possible_drives:Array<String> = ["/dev/sda1", "/dev/sda2", "/dev/sda3"];

    public static function hello():Void {
        trace("Hello");
    }

    // used for getting distro name
    // TODO: extract the distro name through filtering it in a list of distro names produced by
    // uname -a.
    public static function get_distro():String {
        var result:Process = new Process("uname", ["-a"]);
        return result.stdout.readAll().toString();
    }

    // used for getting uptime
    public static function get_uptime():String {
        return new Process("uptime").stdout.readAll().toString();
    }

    // get user name
    public static function get_user():String {
        return new Process("$USER").stdout.readAll().toString();
    }

    // kernel version
    public static function get_kernel_version():String {
        return new Process("uname", ["-r"]).stdout.readAll().toString();
    }

    // get the shell
    public static function get_shell():String {
        return new Process("$SHELL").stdout.readAll().toString();
    }

    // get the terminal emulator
    public static function get_term():String {
        return new Process("echo", ["$TERM"]).stdout.readAll().toString();
    }

    // get amount of installed pkgs, will filter this to each pkg manager later on
    public static function get_pkgs():Int {
        return 2;
    }

    // get RAM
    public static function get_ram():Int {
        return Std.parseInt(new Process("grep", ["MemTotal", "/proc/meminfo"]).stdout.readAll().toString());
    }

    public static function get_main_drive():Drive {
        var r:Array<{Filesystem:String, Size:String, Used:String, Avail:String, UsePct:String, MountedOn:String}> = DfParser.parse(new Process("df").stdout.readAll().toString());

        var main_drive:Drive = {
            Filesys: "",
            Avail: "",
            MountedOn: "",
            Size: "",
            UsePct: "",
            Used: ""
        };

        var largest:Int = 0;

        // find the largest partition
        for (i in r) {
            if (Std.parseInt(i.Size) > largest) {
                largest = Std.parseInt(i.Size);
                main_drive.Filesys = i.Filesystem;
                main_drive.Avail = i.Avail;
                main_drive.MountedOn = i.MountedOn;
                main_drive.Size = i.Size;
                main_drive.UsePct = i.UsePct;
                main_drive.Used = i.Used;
            }

            trace(i.Size);
        }

        return main_drive;
        
    }

    // print the ascii
    public static function print_ascii(distro:String) {
        for (i in FileSystem.readDirectory("ascii")) {
            if (i == distro + ".txt") {
                trace(File.getContent('$distro.txt'));
            }
        }
    }
}


typedef Drive =  {
    var Filesys: String;
    var Size: String;
    var Used: String;
    var Avail: String;
    var UsePct: String;
    var MountedOn:String;
}