var a = process.argv.slice(2);
var vm = require('vm');
var context = vm.createContext({ console: console });
var script = new vm.Script(a[0]);
console.log(script.runInNewContext(context));
