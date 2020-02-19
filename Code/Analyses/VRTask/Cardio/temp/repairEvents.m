

evs = {EEG.event.type};
nevs = {};
for i = 1:length(evs)
    ev = evs{i};
    if ~strcmp(ev, 'boundary')
        tmp = strsplit(ev, 'S');
        numb = tmp{2};
        numbstr = sprintf('%3d', str2num(numb));
        nev = ['S' numbstr];
    else
        nev = ev;
    end
    EEG.event(i).type = nev;
end