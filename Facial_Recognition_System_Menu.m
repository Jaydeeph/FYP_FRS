%% Display The Main Menu:
disp('"Face Recognition": To start detecting and Recognising a face.');
disp('"Add To Database" : To add a person to the databse of faces.');
disp('"Quit"            : To quit the application');

%% Get Users' Input:
User_Answer = lower(input('Please choose from the following options: ', 's'));

%% Load The Correct MATLAB File Depending on User Input via Switch Cases.
switch User_Answer
    case 'face recognition'
        clear;
        clc;
        Facial_Recognition_System;
    case 'add to database'
        clear;
         clc;
        Add_Person_To_Database;
    case 'quit'
        clear;
        clc;
        
    otherwise
        clear;
        clc;
        Facial_Recognition_System;
end















