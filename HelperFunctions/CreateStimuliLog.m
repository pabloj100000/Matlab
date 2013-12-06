function CreateStimuliLog()
    % send an e-mail with all files in StimLogList attached
    global StimLogList    
    Add2StimLogList();
    
    % write the execution date and time in the e-mail
    messageBody = {['Experiment finished running on: ', datestr(clock), '\n']};

    while 1
        try
            mail = configureEmail();
            sendmail(mail, 'Experiment', messageBody, StimLogList)
            break;
        catch
            answer = questdlg('Could NOT send e-mail. Do you want to try again?','','Yes');
            if (~strcmp(answer, 'Yes'));
                answer = questdlg('I will delete the history of what was run.\n Are you sure you do not want to send the e-mail?','','Yes');
                if (strcmp(answer, 'Yes'));
                    break;
                end
            end
        end
    end
    clear global
end

