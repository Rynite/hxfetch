package;

import sys.io.Process;
import DFParser.DfParser;

class Main {
	static function main() {
		trace(DfParser.parse(new Process("df", ["-h"]).stdout.readAll().toString()));
	}
}
