# PowerShell Backup

A simple powershell script for backing up files.



## Installation

* Clone this repo into a PowerShell modules directory, this is the location I use
```
git clone https://github.com/thisiskyle/psbackup.git C:\Users\UserName\Documents\PowerShell\Modules\PSBackup
```

* Add this line to your ```Profile.ps1``` file
```
Import-Module PSBackup
```

* Create your job file, store it anywhere
* Restart PowerShell if needed




## Usage

In PowerShell just run
```
Start-PSBackup \path\to\job\file.json
```



## About the Job File

The job file is just a json file with list of jobs. A job contains the rules for backing up
the desired files to the desired location(s).


### Example Job File

****Note the escaped backslashes**

```
[
    {
        "name": "Example Job 1",
        "active": 1,
        "sourceRoot": "C:\\Users\\UserName\\source",
        "sources": [
            "important_files"
        ],

        "destinations": [
            "B:\\backup\\location"
        ]
    },

    {
        "name": "Example Job 2",
        "active": 0,
        "sourceRoot": "C:\\Users\\UserName\\source2",
        "sources": [
            "more_important_files",
            "specific\\important\\file.txt"
        ],

        "destinations": [
            "B:\\backup\\location",
            "D:\\another\\backup\\location"
        ]
    }
]
```

### Job Object Model

| Variable     | Description                                     |
|--------------|-------------------------------------------------|
| name         | Display name of the job                         |
| active       | Boolean, 1: Active Job, 0: Skip Job             |
| sourceRoot   | Root directory of the files to backup           |
| sources      | List of paths to sources relative to sourceRoot |
| destinations | List of paths to store the source files         |


**A couple things to note**

* Recursive by default. If a source is a directory, 
  all files and subfolders within that directory will be backed up.
  If this is not the desired result, then you must use paths to specific
  files inside the source folder.

* The same directory structure from the source will be mirrored inside 
  the destination directory, see examples below

* Given a 'sourceRoot' without any sources will result in the backup of everything
  inside the 'sourceRoot'


### Example Sources and Outcomes

Source Directory
```
C:\Users\UserName\source
                     |
                     |__\important_files
                     |           |__\file1.txt
                     |           |__\file2.txt
                     |
                     |__\other_files
                     |           |__\file3.txt
                     |
                     |__\specific_file
                                 |__\file4.txt
                                 |__\file5.txt
                                 |__\file6.txt
```

Backup Directory
```
B:\backup\location
```

Job File
```
[
    {
        "name": "Example Job 1",
        "active": 1,
        "sourceRoot": "C:\\Users\\UserName\\source",
        "sources": [
            "important_files",
            "specific_file\\file4.txt"
        ],

        "destinations": [
            "B:\\backup\\location"
        ]
    }
]
```

Resulting Backup
```
B:\backup\location
               |
               |__\important_files
               |           |__\file1.txt
               |           |__\file2.txt
               |
               |__\specific_file
                           |__\file4.txt
```
