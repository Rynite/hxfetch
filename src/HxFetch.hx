import haxe.Json;
import DFParser.DfParser;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
import Sys.print;
import Console;


using StringTools;


// This class won't be neofetch dependent, it'll essentially use coreutils

// IMPORTANT, IF CONFIG.json IS PROVIDED, CMD LINE ARGS WILL BE INGORED

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

    public static var config = Json.parse(File.getContent("config.json"));


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
        var user:String = new Process("bash", ["-c", "echo $USER"]).stdout.readAll().toString().trim();
        var distro:String = get_distro().fetch.replace("os", "");
        
        return {title: "", fetch: user + "@" + distro}; // <white/> hello </>
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
        var total:Int = Std.int(Std.parseInt(new Process("grep", ["MemTotal", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemTotal: ", "").trim()) / 1024);
        var free:Int = Std.int(Std.parseInt(new Process("grep", ["MemFree", "/proc/meminfo"]).stdout.readAll().toString().replace("kB","").replace("MemFree: ","").trim()) / 1024);

        return {title: "memory: ", fetch: free + " MiB" + " / " + total + " MiB"};

    }

    // get the dimensions
    public static function get_dimensions():Detail {
        return {title: "resolution: ", fetch: new Process("bash", ["-c", "xdpyinfo | awk '/dimensions/{print $2}'"]).stdout.readAll().toString()};
    }

    // get wm (currently using wmctrl, but I'll find a way to find the wm without it later :<)
    public static function get_wm():Detail {
        return {title: "wm: ", fetch: new Process("bash", ["-c", "wmctrl -m | grep Name | cut -d: -f2"]).stdout.readAll().toString()};
    }

    // get the currently used DE
    public static function get_de():Detail {
        // check if there's even a DE
        var f:String = new Process("bash", ["-c", "echo $XDG_CURRENT_DESKTOP"]).stdout.readAll().toString();
        if (f == "") {
            return {title: "", fetch: ""};
        }

        return {title: "de: ", fetch: f};
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
        var wm:Detail = get_wm();
        var de:Detail = get_de();
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
            user, distro, host, kernel, wm, de, shell, uptime, gpu, cpu, res, te, mem
        ].map(function f(f):Detail {
            return {title: f.title, fetch: f.fetch.replace('\n',""), title_color: ArgumentParser.color1, fetch_color: ArgumentParser.color2};
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
        var index:Int = 0;
        var arr_to_print:Array<Detail> = get_fetch_details();
        
        switch (ArgumentParser.layout) {
            
            case ("right"):
                
                // Find the longest line
                for (line in ascii_lines) {
                    if (line.length > longest) {
                        longest = line.length;
                    }
                }
                // align them
                for (line in ascii_lines) {
                    
                    // just in case there is no DE
                    if (arr_to_print[index] != null) {
                        if (arr_to_print[index].title == "de: ") {
                            index++;
                            continue;
                        }
                    }
        
                    // print one line of the ascii
                    Console.log('<' + ArgumentParser.color1 + ',b>' + line + '</>');
                    
                    // print spaces to push them nicely
                    for (_ in 0...(longest-line.length)+step) {
                        Console.log('<white> </white>');
                    }
                    
                    // print the fetch details
                    if (arr_to_print[index] != null) {
                        Console.log('<' + arr_to_print[index].title_color + '>' + arr_to_print[index].title + '</>');
                        Console.log('<' + arr_to_print[index].fetch_color + '>' + arr_to_print[index].fetch + '</>');
                    }
                        
                    // finally print a new line so it doesn't look like a terrible mess :)
                    print('\n');
                    
                    index++;
                

        }
            case ("left"):
                ascii_lines = File.getContent("ascii/" + distro + ".txt").split("\n");
                step = 2;   
                longest = 0;
                index = 0;
                arr_to_print = get_fetch_details();


                // Find the longest line in the fetch details
                for (line in arr_to_print) {
                    if (line.title.length + line.fetch.length > longest) {
                        longest = line.title.length + line.fetch.length;
                    }
                }
                // align them
                for (line in ascii_lines) {
                    
                    // just in case there is no DE
                    if (arr_to_print[index] != null) {
                        if (arr_to_print[index].title == "de: ") {
                            index++;
                            continue;
                        }
                    }
                    
                    // print the fetch details
                    if (arr_to_print[index] != null) {
                        Console.log('<' + arr_to_print[index].title_color + '>' + arr_to_print[index].title + '</>');
                        Console.log('<' + arr_to_print[index].fetch_color + '>' + arr_to_print[index].fetch + '</>');
                    }

                    if (arr_to_print[index] != null) {
                        // print spaces to push them nicely
                        for (_ in 0...(longest-(arr_to_print[index].title.length + arr_to_print[index].fetch.length))+step) {
                            Console.log('<white> </white>');
                        }
                    } else {
                        for (_ in 0...longest-step+4) {
                            Console.log('<white> </white>');
                        }
                    }

                    // print one line of the ascii
                    Console.log('<' + ArgumentParser.color1 + ',b>' + line + '</>');
                    
                        
                    // finally print a new line so it doesn't look like a terrible mess :)
                    print('\n');
                    
                    index++;
                }

            case ("up"):

                ascii_lines = File.getContent("ascii/" + distro + ".txt").split("\n");
                step = 2;   
                longest = 0;
                index = 0;
                arr_to_print = get_fetch_details();


                // print the ascii
                for (line in ascii_lines) {
                    Console.log('<' + ArgumentParser.color1 + ',b>' + line + '</>');
                    print('\n');
                }

                print('\n');

               // print details
               for (i in arr_to_print) {
                    // just in case there is no DE
                    if (i != null) {
                        if (i.title == "de: ") {
                            continue;
                        }
                    }
                    // print white space
                    Console.log("<white>" + " " + "</>");
                    // print a detail
                    Console.log('<' + i.title_color + '>' + i.title + '</>');
                    Console.log("<" + i.fetch_color + ">" + i.fetch + "</>");
                    print('\n');
               }

               
                    
                        
                // finally print a new line so it doesn't look like a terrible mess :)
                print('\n');
                
                index++;
            
            case ("down"):
                ascii_lines = File.getContent("ascii/" + distro + ".txt").split("\n");
                step = 2;   
                longest = 0;
                index = 0;
                arr_to_print = get_fetch_details();

                // print details
                for (i in arr_to_print) {
                     // just in case there is no DE
                     if (i != null) {
                         if (i.title == "de: ") {
                            continue;
                         }
                     }
                     // print white space
                     Console.log("<white>" + " " + "</>");
                     // print a detail
                     Console.log('<' + i.title_color + '>' + i.title + '</>');
                     Console.log("<" + i.fetch_color + ">" + i.fetch + "</>");
                     print('\n');
                }

                // print the ascii
                for (line in ascii_lines) {
                    Console.log('<' + ArgumentParser.color1 + ',b>' + line + '</>');
                    print('\n');
                }

                print('\n');


               
                    
                        
                // finally print a new line so it doesn't look like a terrible mess :)
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
    @:optional var title_color:String;
    @:optional var fetch_color:String;
}