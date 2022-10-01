import DFParser.DfParser;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
import Sys.print;
import Console;


using StringTools;


// This class won't be neofetch dependent, it'll essentially use coreutilss
class HxFetch {

    public static var distros:Array<String> = [
        "archlinux",
        "openbsd"
    ];

    public static var terms:Array<String> = [
        "kitty",
        "rxvt",
        "xterm-256color"
    ];


    public static var possible_drives:Array<String> = ["/dev/sda1", "/dev/sda2", "/dev/sda3"];

    public static function hello():Void {
        trace("Hello");
    }

    // used for getting distro name
    // TODO: extract the distro name through filtering it in a list of distro names produced by
    // uname -a.
    public static function get_distro():Detail {
        var result:String = new Process("uname", ["-n"]).stdout.readAll().toString().replace('\n',"");
        var f_distro = "";
        for(distro in distros) {
            if (distro == result) {
                f_distro = distro;
            }
        }
        return {title: "os: ", fetch: f_distro};
    }

    // get the product details
    public static function get_host():Detail {
        var product_name:String = new Process("cat", ["/sys/devices/virtual/dmi/id/product_name"]).stdout.readAll().toString();
        var product_version:String = new Process("cat", ["/sys/devices/virtual/dmi/id/product_version "]).stdout.readAll().toString();
        var host:String = product_name + product_version;

        return {title: "host: ", fetch: host};
    }

    // get the GPU
    public static function get_gpu():Detail {
        var gpu:String = "";
        var o = new Process("bash", ["-c", "lspci | grep VGA"]).stdout.readAll().toString();
        var gpu_main:String = "";
        var model:String = "";
        
        // first get the main GPU's name
        for (g in ["NVIDIA", "AMD"]) {
            if (o.contains(g)) {
                gpu_main = g;
            }
        }

        // get the model name
        var r:EReg = ~/.*\[AMD\/ATI\]|.*(\[.*\])/;
        r.match(o);
        if (gpu_main == "NVIDIA") {
            model = r.matched(1);
        } else if (gpu_main == "AMD") {
            model = r.matched(2);
        }

        return {title: "gpu: ", fetch: gpu_main + " " + model.replace("[","").replace("]", "")};
        
    }

    // get the cpu
    public static function get_cpu():Detail {
        var ghz:String = "";
        var model:String = "";
        // first get the number of cores
        var cores:String = new Process("bash", ["-c", "cat /proc/cpuinfo | grep processor | wc -l"]).stdout.readAll().toString();
        // now get the processor information
        var o:String = new Process("bash", ["-c", "cat /proc/cpuinfo | grep 'model name' | uniq"]).stdout.readAll().toString().replace("CPU", "");
        var proc:String = "";
        // make sure if its intel (ill fix later for other procs)
        if (o.contains("Intel")) {
            proc = "Intel";
        }

        // find the model name
        var r:EReg = ~/.*\)(.*)@(.*)/;
        r.match(o);

        model = r.matched(1);
        ghz = r.matched(2);

        return {title: "cpu: ", fetch: proc + " " + model.replace(" ","").trim() + " @ " + ghz.ltrim()}
    }

    // used for getting uptime
    public static function get_uptime():Detail {
        var o:String = new Process("uptime").stdout.readAll().toString();
        var r:EReg = ~/(.[0-9]*:[0-9]*:[0-9]*)/;
        r.match(o);

        return {title: "uptime: ", fetch: r.matched(1)};
    }

    // get user name
    public static function get_user():Detail {
        return {title: "", fetch: new Process("bash", ["-c", "echo $USER"]).stdout.readAll().toString() + "@" + get_distro().fetch.replace("os: ","") + '\n'};
    }

    // the dashes thing
    public static function get_dashes():String {
        var dashes:String = "";

        for (d in 0...get_user().fetch.length) {
            dashes+="-";
        }

        return dashes;
    }

    // kernel version
    public static function get_kernel_version():Detail {
        return {title: "kernel version: ", fetch: new Process("uname", ["-r"]).stdout.readAll().toString()}
    }

    // get the shell
    public static function get_shell():Detail {
        var shell:String = new Process("bash", ["-c", "echo $SHELL"]).stdout.readAll().toString();

        return {title: "shell: ", fetch: shell.replace("/usr/bin/", "")};
    }

    // get the terminal emulator
    public static function get_term():Detail {
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
        } else if (terminal == "xterm-256color") {
            terminal = "vscode";
        }

        return {title: "terminal: ", fetch: terminal};
    }

    // get amount of installed pkgs, will filter this to each pkg manager later on
    public static function get_pkgs():Int {
        return 2;
    }

    // get RAM
    public static function get_ram():Detail {
        var total:Int = Std.int(Std.parseInt(new Process("grep", ["MemTotal", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemTotal: ", "").trim()) / 1000);
        var free:Int = Std.int(Std.parseInt(new Process("grep", ["MemFree", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemFree: ","").trim()) / 1000);

        return {title: "memory: ", fetch: free + " MiB" + " / " + total + " MiB"};

    }

    // get the dimensions
    public static function get_dimensions():Detail {
        return {title: "resolution: ", fetch: new Process("bash", ["-c", "xdpyinfo | awk '/dimensions/{print $2}'"]).stdout.readAll().toString()};
    }

    public static function get_fetch_details():Array<Detail> {
        var r:Array<{Filesystem:String, Size:String, Used:String, Avail:String, UsePct:String, MountedOn:String}> = DfParser.parse(new Process("df").stdout.readAll().toString());

        var user:Detail = get_user();
        var distro:Detail = get_distro();
        var host:Detail = get_host();
        var kernel:Detail = get_kernel_version();
        var uptime:Detail = get_uptime();
        // var packages:Detail = "";
        var shell:Detail = get_shell();
        var res:Detail = get_dimensions();
        var wm:String = "";
        var de:String = "";
        var theme:String = "";
        var icons:String = "";
        var te:Detail = get_term();
        var cpu:Detail = get_cpu();
        var gpu:Detail= get_gpu();
        var mem:Detail = get_ram();
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
            user, distro, host, kernel, shell, uptime, gpu, cpu, res, te, mem
        ].map(function f(f):Detail {
            return {title: f.title, fetch: f.fetch.replace('\n',"")};
        });

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
        var arr_to_print:Array<Detail> = get_fetch_details();

      

        // align them
        for (line in ascii_lines) {

            Console.log('<' + ArgumentParser.color1 + ',b>' + line + '</>');
            
            for (_ in 0...(longest-line.length)+step) {
                Console.log('<white> </white>');
            }

            if (arr_to_print[index] != null) {
                Console.log('<' + ArgumentParser.color1 + '>' + arr_to_print[index].title + '</>');
                Console.log('<' + ArgumentParser.color2 + '>' + arr_to_print[index].fetch + '</>');
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

typedef Detail = {
    var title:String;
    var fetch:String;
}