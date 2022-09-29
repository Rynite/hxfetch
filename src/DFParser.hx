package ;

class DfParser {
    public static function parse(i:String):Array<{Filesystem:String, Size:String, Used:String, Avail:String, UsePct:String, MountedOn:String}> {
		final result:String = i;
		var resultArr:Array<String> = ~/(?=\n)/gm.split(result);
		resultArr = resultArr.filter((s) -> {return if (s == "\n") false else true;});
		resultArr.splice(0, 1);
		var retarr:Array<{Filesystem:String, Size:String, Used:String, Avail:String, UsePct:String, MountedOn:String}> = [];

		for (e in resultArr) {
			var data = ~/ +/gmi.split(e);
			retarr.push({
				Filesystem: data[0],
				Size: data[1],
				Used: data[2],
				Avail: data[3],
				UsePct: data[4],
				MountedOn: data[5]
			});
		}
		return retarr;
	}
}