Screen('Resolution', max(Screen('Screens')), 1680, 1050, 0);
%Screen('Resolution', 1, 800, 600, 120);
RF('movieDurationSecs', 5)
pause(.2);
Mouse_Eye_Movement(3, 'center_size', 5, 'obj_contrast', .5);
pause(.2);
RF_timestamp('movieDurationSecs', 10);
pause(.2);
add_experiments_to_db();
FinishExperiment();
