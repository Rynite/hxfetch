import DFParser.DfParser;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
import Sys.print;
import Console;
import hxargs.Args;

using StringTools;


// This class won't be neofetch dependent, it'll essentially use coreutilss
class HxFetch {

   

    public static var distros:Array<String> = [
        "archlinux",
        "openbsd"
    ];

    public static var terms:Array<String> = [
        "kitty",
        "rxvt"
    ];


    public static var possible_drives:Array<String> = ["/dev/sda1", "/dev/sda2", "/dev/sda3"];

    public static function hello():Void {
        trace("Hello");
    }

    // used for getting distro name
    // TODO: extract the distro name through filtering it in a list of distro names produced by
    // uname -a.
    public static function get_distro():String {
        var result:String = new Process("uname", ["-n"]).stdout.readAll().toString().replace('\n',"");
        var f_distro = "";
        for(distro in distros) {
            if (distro == result) {
                f_distro = distro;
            }
        }



        return "os: " + f_distro;
    }

    // get the product details
    public static function get_host():String {
        var product_name:String = new Process("cat", ["/sys/devices/virtual/dmi/id/product_name"]).stdout.readAll().toString();
        var product_version:String = new Process("cat", ["/sys/devices/virtual/dmi/id/product_version "]).stdout.readAll().toString();
        var host:String = product_name + product_version;

        return "host: " + host;
    }

    // used for getting uptime
    public static function get_uptime():String {
        var o:String = new Process("uptime").stdout.readAll().toString();
        var r:EReg = ~/(.[0-9]*:[0-9]*:[0-9]*)/;
        r.match(o);
        return "uptime: " + r.matched(1);
    }

    // get user name
    public static function get_user():String {
        var ud:String = new Process("bash", ["-c", "echo $USER"]).stdout.readAll().toString() + "@" + get_distro().replace("os: ","") + '\n';
        return ud;
    }

    // the dashes thing
    public static function get_dashes():String {
        var dashes:String = "";

        for (d in 0...get_user().length) {
            dashes+="-";
        }

        return dashes;
    }

    // kernel version
    public static function get_kernel_version():String {
        return "kernel version: " + new Process("uname", ["-r"]).stdout.readAll().toString();
    }

    // get the shell
    public static function get_shell():String {
        var shell:String = new Process("bash", ["-c", "echo $SHELL"]).stdout.readAll().toString();

        return "shell: " + shell.replace("/usr/bin/", "");

    }

    // get the terminal emulator
    public static function get_term():String {
        var te:String = new Process("bash", ["-c", "echo $TERM"]).stdout.readAll().toString();
        var terminal:String = "";

        for (t in terms) {
            var r:EReg = new EReg('$t', "i");
            if (r.match(te)) {
                terminal = t;
            }
        }

        // just some special cases
        if (terminal == "rxvt") {
            terminal = "urxvt";
        }

        return "terminal: " + terminal;
    }

    // get amount of installed pkgs, will filter this to each pkg manager later on
    public static function get_pkgs():Int {
        return 2;
    }

    // get RAM
    public static function get_ram():String {
        var total:Int = Std.int(Std.parseInt(new Process("grep", ["MemTotal", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemTotal: ", "").trim()) / 1000);
        var free:Int = Std.int(Std.parseInt(new Process("grep", ["MemFree", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemFree: ","").trim()) / 1000);

        return "memory: " + free + " MiB" + " / " + total + " MiB";

    }

    // get the dimensions
    public static function get_dimensions():String {
        return "resolution: " + new Process("bash", ["-c", "xdpyinfo | awk '/dimensions/{print $2}'"]).stdout.readAll().toString();
    }

    public static function get_fetch_details():Array<String> {
        var r:Array<{Filesystem:String, Size:String, Used:String, Avail:String, UsePct:String, MountedOn:String}> = DfParser.parse(new Process("df").stdout.readAll().toString());

        var user:String = get_user();
        var distro:String = get_distro();
        var host:String = get_host();
        var kernel:String = get_kernel_version();
        var uptime:String = get_uptime();
        var packages:String = "";
        var shell:String = get_shell();
        var res:String = get_dimensions();
        var wm:String = "";
        var de:String = "";
        var theme:String = "";
        var icons:String = "";
        var te:String = get_term();
        var cpu:String = "";
        var gpu:String = "";
        var mem:String = get_ram();
        var dashes:String = get_dashes();

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
        }
        
        return [
            user, dashes, distro, host, kernel, shell, uptime, res, te, mem
        ].map(f -> f.replace('\n',""));

    }

   

    // get the distro ascii
    public static function get_ascii(distro:String):String {
        var ascii_str:String = "";
        for (i in FileSystem.readDirectory("ascii")) {
            if (i == distro + ".txt") {
                ascii_str = File.getContent("ascii/" + distro + ".txt");
            }
        }
        return ascii_str;
    }

    public static function print_fetch(distro:String) {

        // some important vars
        var ascii_lines:Array<String> = File.getContent("ascii/" + distro + ".txt").split("\n");
        var step:Int= 2;   
        var longest:Int = 0;

        // Find the longest line
        for (line in ascii_lines) {
            if (line.length > longest) {
                longest = line.length;
            }
        }

        var index:Int = 0;
        var arr_to_print:Array<String> = get_fetch_details();

        // align them
        for (line in ascii_lines) {
            print(line);
            for (space in 0...(longest-line.length)+step) {
                print(" ");
            }

            if (arr_to_print[index] != null) {
                print(arr_to_print[index]);
            }

            print('\n');

            index++;
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