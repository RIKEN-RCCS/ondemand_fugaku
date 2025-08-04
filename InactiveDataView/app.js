const express = require('express');
const path = require('path');
const fs = require('fs');
const os = require('os');
const app = express();
const port = 3000;
const { execSync } = require('child_process');
const dataPath = "/vol0001/system/tool/filesystem_reference";
//const dataPath = path.join(__dirname, 'data');

// have to use a Router to mount the `PASSENGER_BASE_URI`
// base uri that's /pun/dev/appname or /pun/sys/appname depending
// on the environment.
const router = express.Router();
app.use(process.env.PASSENGER_BASE_URI || '/', router);

// index page
router.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// Read a specific JSON file from the `dataPath` directory based on the filename provided in the URL.
// Respond with the parsed JSON content if the file exists and is valid.
// If the file cannot be read or parsed, responds with HTTP 500 and an appropriate error message.
router.get('/api/:group.json', (req, res) => {
    const group = req.params.group;
    const username = os.userInfo().username;
    const filePath1 = path.join(dataPath, `${group}.json`);
    const filePath2 = path.join(dataPath, `${group}_${username}.json`);

    let filePath = null;
    try {
	fs.accessSync(filePath1, fs.constants.F_OK | fs.constants.R_OK);
	filePath = filePath1;
    } catch {
	try {
	    fs.accessSync(filePath2, fs.constants.F_OK | fs.constants.R_OK);
	    filePath = filePath2;
	} catch {
	    return res.status(404).json({error: `File not found or not readable: ${filePath1} or ${filePath2}`});
	}
    }
    
    try {
	const data = fs.readFileSync(filePath, 'utf8');
	const json = JSON.parse(data);
	res.json(json);
    } catch (err) {
	const message = err instanceof SyntaxError
	      ? 'Failed to parse JSON: ' + err.message
	      : 'Failed to read file: ' + err.message;
	res.status(500).json({ error: message });
    }
});

//  Return a list of group names for which a corresponding JSON file exists and is readable.
router.get('/api/list', (req, res) => {
    try {
	const groups = execSync('groups', { encoding: 'utf8' }).trim().split(/\s+/);
	const username = os.userInfo().username;
	
	const validGroups = groups.filter(group => {
	    const fullPath1 = path.join(dataPath, `${group}.json`);
	    const fullPath2 = path.join(dataPath, `${group}_${username}.json`);

	    try {
		fs.accessSync(fullPath1, fs.constants.F_OK | fs.constants.R_OK);
		return true;
	    } catch {
		try {
		    fs.accessSync(fullPath2, fs.constants.F_OK | fs.constants.R_OK);
		    return true;
		} catch {
		    return false;
		}
	    }
	});
	res.json(validGroups);
    } catch (err) {
	res.status(500).json({
	    error: 'Failed to execute groups command: ' + err.message
	});
    }
});

// start the server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});

