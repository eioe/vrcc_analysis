function sent = send_dbl_mrkr_fuckup(mrkr)

if mrkr.screendelay > 0
    sent = send_mrkr_v2(mrkr.name, mrkr.portadr);
    waitframes = mrkr.screendelay * mrkr.hertz;
else
    waitframes = 1;
end

% Color rect white:
rectColor = mrkr.col.white;
Screen('FillRect', mrkr.window, rectColor, mrkr.rect);
% Flip to the screen after delay:
vbl = GetSecs;
vbl = Screen('Flip', mrkr.window, vbl + (waitframes - 0.5) * mrkr.ifi);
fprintf(['\n\n' num2str(waitframes) '\n\n']);
if mrkr.screendelay == 0
    sent = send_mrkr_v2(mrkr.name, mrkr.portadr);
end

% Paint back to black after 1 frame:    
rectColor = mrkr.col.black;
Screen('FillRect', mrkr.window, rectColor, mrkr.rect);
vbl = Screen('Flip', mrkr.window, vbl + (1 - 0.5) * mrkr.ifi);

if mrkr.screendelay < 0
    sendtime = 0;
    while sendtime < vbl + abs(mrkr.screendelay)
        sendtime = GetSecs;
    end
    sent = send_mrkr_v2(mrkr.name, mrkr.portadr);
end

end

