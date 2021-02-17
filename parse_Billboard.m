%% Parse the chord symbols in the Billboard data set using the Relative Root encoding scheme.
%
% *Billboard DATA SET*
%
%   Download: <https://ddmal.music.mcgill.ca/research/The_McGill_Billboard_
%              Project_(Chord_Analysis_Dataset)/>
%   Citation: John Ashley Burgoyne, Jonathan Wild, and Ichiro Fujinaga, ‘An 
%             Expert Ground Truth Set for Audio Chord Recognition and Music 
%             Analysis’, in Proceedings of the 12th International Society 
%             for Music Information Retrieval Conference, ed. Anssi Klapuri 
%             and Colby Leider (Miami, FL, 2011), pp. 633–38
%
% *PARSE -- Relative Root Representation* 
%
%   Encoding:    <RN><Quality><Inversion><Extensions>
%
%     RN         -- Roman numeral encoded in relation to the key. Case
%                   denotes quality of the triad (major or minor).
%                   Named chords (+6, Ct, etc.) are converted to RN roots,
%                   with the names included in the quality slot (e.g., 
%                   #ivGer). Applied dominants (e.g., V/ii) receive 
%                   diatonic equivalents. Chords may also be preceded by a
%                   chromatic accidental relative to the major scale 
%                   (e.g., viio/V --> #ivo):
%                       --  double flat
%                        -  flat 
%                        #  sharp
%                       ##  double sharp
%
%     Quality    -- Chord quality:
%                        M  major seventh
%                           minor seventh (no symbol)
%                        d  major RN with minor seventh (minor RN with 
%                        h  half-diminished seventh
%                        o  diminished triad or seventh
%                        +  augmented triad or seventh
%                        p  power (i.e., no 3rd)
%                      Ger  German augmented sixth (never annotated in this
%                           data set)
%                       Fr  French augmented sixth (never annotated in this
%                           data set)
%                       It  Italian augmented sixth (never annotated in
%                           this data set)
%                       Ct  Common-tone diminished seventh (never annotated
%                           in this data set)
%
%     Inversion  -- Chord inversion:
%                           root position (no symbol)
%                        6  first inversion triad
%                       64  second inversion triad
%                        7  root position seventh
%                       65  first inversion seventh
%                       43  second inversion seventh
%                       42  third inversion seventh 
%
%     Extensions -- Suspensions or added tones appear in parentheses, with
%                   added tones preceded by '+'.
%
%   Example:     V(64) (i.e., a cadential six-four)
%
% *DEPENDENCIES*
%
%                -- None.
%
% *HISTORY*
%
%   Date:          2.16.2021          
%   Time:          12:59	
%   Programmer:    David Sears	    
%   Version:       MATLAB 9.6 (R2019a, PC)


%% IMPORT
warning('off')

% Index of songs.
cd('<file_path>\McGill_Billboard\all_data\McGill-Billboard')
fnames = dir;
fnames = {fnames.name}';
fnames(ismember(fnames,{'.' '..'})) = [];
fnames_idx = str2num(char(fnames));

% Import song info.
cd('<file_path>\McGill_Billboard')
%song_info = importdata('billboard-2.0-index.csv');
fid = fopen('billboard-2.0-index_nocommas.csv');
C = textscan(fid,'%s %s %s %s %s %s %s %s','Delimiter',',');
fclose(fid);
song_info.data = [C{:,1} C{:,2} C{:,3} C{:,4} C{:,5} C{:,6} C{:,7} C{:,8}];
song_info.header = song_info.data(1,:);
song_info.data(1,:) = [];
song_info.songnum = str2num(char(song_info.data(:,1)));

% Delete song info that doesn't contain chord annotations. (There are 890
% annotated songs.)
[~,idx] = ismember(fnames_idx,song_info.songnum);
song_info.data = song_info.data(idx,:);
song_info.year = year(datetime(song_info.data(:,2)));

% Ignore duplicates. (There are 740 unique songs.)
names = song_info.data(:,5:6);
names = regexprep(names, '[.,'') ("!?]', '');
names = strcat(names(:,1),names(:,2));
[~,idx] = unique(names);
files = fnames(idx);
fnames = strcat('Billboard_',files);
song_info.data = song_info.data(idx,:);
song_info.year = song_info.year(idx);

% Import key information.
len = size(fnames,1);
cd('<file_path>\McGill_Billboard\all_data\McGill-Billboard')
for i = 1:len
    cd(files{i})
    file = dir('*.txt');
    tmp = importdata(file.name);
    idx = find(contains(tmp,'tonic:'));
    keys = tmp(idx);
    keys = strtrim(extractAfter(keys,'tonic:'));
    times = 0;
    if length(keys)>1
       for j = 2:length(idx)
           ln = tmp(idx(j)+1);
           ln = regexp(ln, '(\d+,)*\d+(\.\d*)?', 'match');
           ln = ln{:};
           times(j) = str2num(ln{1});
       end
    end
    data.(fnames{i}).keys = keys;
    data.(fnames{i}).key_onsets = times;
    clear file tmp idx keys times
    cd ..
end

% Import chord data.
cd('<file_path>\McGill_Billboard\chord_labels\McGill-Billboard')
for i = 1:len
    cd(files{i})
    file = dir('*.lab');
    tmp = tdfread(file.name,'\t');
    nm = fieldnames(tmp);
    data.(fnames{i}).onsets = tmp.(nm{1});
    data.(fnames{i}).chords = tmp.(nm{end});
    clear file tmp nm
    cd ..
end


%% PREPROCESS
    
PCs = {'Fbb' 'Cbb' 'Gbb' 'Dbb' 'Abb' 'Ebb' 'Bbb' ...
      'Fb' 'Cb' 'Gb' 'Db' 'Ab' 'Eb' 'Bb' ...
      'F' 'C' 'G' 'D' 'A' 'E' 'B' ...
      'F#' 'C#' 'G#' 'D#' 'A#' 'E#' 'B#' ...
      'F##' 'C##' 'G##' 'D##' 'A##' 'E##' 'B##'};
  
RNs = {'--IV' '--I' '--V' '--II' '--VI' '--III' '--VII' ...
       '-IV' '-I' '-V' '-II' '-VI' '-III' '-VII' ...
       'IV' 'I' 'V' 'II' 'VI' 'III' 'VII' ...
       '#IV' '#I' '#V' '#II' '#VI' '#III' '#VII' ...
       '##IV' '##I' '##V' '##II' '##VI' '##III' '##VII'};
for i = 1:len

    % Create variables.
    keys = data.(fnames{i}).keys;
    key_onsets = data.(fnames{i}).key_onsets;
    onsets = data.(fnames{i}).onsets;
    chords = data.(fnames{i}).chords;
    chords = cellstr(chords);
    
    % Exclude repetitions and nonchords ('X' and 'N').
    idx = find(contains(chords,{'X' 'N' ':1/1'}));
    onsets(idx) = [];
    chords(idx) = [];
    
    % Separate PC roots from remainder info (i.e., after ':').
    [roots remain] = strtok(chords,':');
    
    if ~isempty(chords)
    

        %% CONVERT (relative root representation)  
        
        % RN
        
        % Gather key annotations.
        key_onsets(end+1) = onsets(end)+1;
        for j = 2:length(key_onsets)
            idx = find(onsets >= key_onsets(j-1) & onsets < key_onsets(j));
            new_keys(idx,1) = keys(j-1);
        end
        keys = new_keys; clear new_keys

        % Convert roots.  
        [~,keys_idx] = ismember(keys,PCs);
        [~,roots_idx] = ismember(roots,PCs);
        tonic = find(ismember(RNs,'I'));
        root_nums = mod(roots_idx - keys_idx+tonic, length(PCs));
        root_RNs = [RNs(root_nums)]';

        % QUALITY
        
        % Quality of triads/seventh chords that changes RN and/or form label.
        forms = cell(length(chords),1);
        
        % maj7
        idx = find(contains(remain,{'maj7' 'maj9'}));
        forms(idx) = {'M'};
        
        % min   
        idx = find(contains(remain,':min')); 
        root_RNs(idx) = lower(root_RNs(idx));
        
        % dim
        idx = find(contains(remain,':dim')); 
        root_RNs(idx) = lower(root_RNs(idx));
        forms(idx) = {'o'};

        % hdim
        idx = find(contains(remain,':hdim')); 
        root_RNs(idx) = lower(root_RNs(idx));
        forms(idx) = {'h'};

        % aug
        idx = find(contains(remain,':aug')); 
        forms(idx) = {'+'};

        % A maj chord with a non-V root and a 7th needs a 'd'.
        idx = isstrprop(root_RNs,'upper');
        for j = 1:length(idx)
            if any(idx{j})==1
                idx2(j,1) = 1;
            else idx2(j,1) = 0;
            end
        end
        idx = find(idx2==1);
        idx2 = find((ismember(remain,':7') | contains(remain,'b7')) & ~ismember(root_RNs,'V'));
        idx = intersect(idx,idx2);
        forms(idx) = {'d'};
        
        % 5 = power chord
        idx = find(contains(remain,':5'));
        forms(idx) = {'p'};
        p_idx = idx;
        
        
        % INVERSION
        
        % Replace chordal extensions with '7' (you're going to put the
        % extensions in changes).
        [ext inv] = strtok(remain,'/');
        ext = replace(ext,'b','-');
        [ext changes] = strtok(ext,'(');
        inv = erase(inv,{'/' 'b' '#'});
        ext = erase(ext,{':5' ':minmaj' ':maj6' ':maj' ':min' ':dim' ':aug' ':hdim' ':sus2' ':sus4'});
        ext = replace(ext,{':7' ':9' ':11' ':13' '9'},'7');
        inv = erase(inv,{'1' '2' '4' '6' '8'});
        idx = find(contains(changes,{'7' '9' '11' '13'})); % Add a 7th if chordal extensions appear in changes.
        ext(idx) = {'7'};
        
        % Create the inversions.
        figbass = ext;
        figbass(~ismember(ext,'7') & ismember(inv,'3')) = {'6'};
        figbass(ismember(ext,'7') & ismember(inv,'3')) = {'65'};
        figbass(~ismember(ext,'7') & ismember(inv,'5')) = {'64'};
        figbass(ismember(ext,'7') & ismember(inv,'5')) = {'43'};
        figbass(ismember(inv,'7')) = {'42'};
        
        % Ignore '5' annotations in figbass for power chords.
        figbass(p_idx) = {''};
   
        
        % EXTENSIONS
        [ext inv] = strtok(remain,'/');
        ext = replace(ext,'b','-');
        inv = replace(inv,'b','-');
        [ext changes] = strtok(ext,'(');
        changes = erase(changes,{'(' ')'});
        
        % Move extensions to changes.
        ext = erase(ext,{':' 'maj' 'min' 'aug' 'dim' 'hdim' 'sus' '7'});
        ext = replace(ext,{'2' '4' '6' '9' '11' '13'},{'2,' '4,' '6,' '9,' '11,' '13,'});
        changes = strcat(changes,',',ext);

        % Move inverted basses to changes that aren't 3, 5, or 7
        inv = erase(inv,{'3' '5' '7' '-3' '-5' '-7' '/'});
        changes = strcat(changes,',',inv);
        
        % Ignore '5' annotations in changes for power chords.
        changes(p_idx) = erase(changes(p_idx),'5');
        
        % Add cadential six-four 'V(64)' to I64-V progressions.
        idx = find((strcmp(root_RNs,'I') | strcmp(root_RNs,'i')) & strcmp(figbass,'64'));
        if ~isempty(idx) && idx(end)==length(chords)
            idx(end) = [];
        end
        tmp = [root_RNs(idx) root_RNs(idx+1)];
        if ~isempty(tmp)
            change = strcmp(tmp(:,2),'V');
            tmp = tmp(:,1);
            tmp(change) = {'V'};
            root_RNs(idx) = tmp;
            changes(idx(change)) = strcat(changes(idx(change)),'6,4');
            figbass(idx(change)) = erase(figbass(idx(change)),'64');
        end

        % Tokenize extensions and separate accidentals.
        t = cellfun(@(x) length(strfind(x,',')),changes,'UniformOutput',false);
        t = max(cell2mat(t));
        ext_tab = cell(length(changes),t+1);
        acc_tab = ext_tab;
        tmp = changes;
        for j = 1:t+1
            [ext_tab(:,j) tmp] = strtok(tmp,',');
            idx = find(contains(ext_tab(:,j),'#'));
            acc_tab(idx,j) = {'#'};
            idx = find(contains(ext_tab(:,j),'-'));
            acc_tab(idx,j) = {'-'};
            clear idx
        end
        ext_tab = erase(ext_tab,{'-' '#'});
        ext_tab(cellfun(@isempty, ext_tab)) = {'0'};
        ext_tab = str2double(ext_tab);
        [ext_tab idx] = sort(ext_tab,2,'descend');
        
        % Delete repetitions of extensions.
        tmp = ext_tab;
        tmp(tmp==0) = nan;
        idxrep = [false(size(ext_tab,1),1) ~diff(ext_tab,1,2)];
        idxrep(isnan(tmp)) = 0;
        ext_tab(idxrep==1) = 0;
        
        for j = 1:size(ext_tab,1)
            acc_tab(j,:) = acc_tab(j,idx(j,:));
        end
        ext_tab = arrayfun(@num2str, ext_tab, 'UniformOutput', 0);
        idx = find(ismember(ext_tab,'0'));
        ext_tab(idx) = {''};  
        
        % Put ext and acc back together.
        idx = find(~cellfun(@isempty,ext_tab(:,2:end)));
        tab = strcat(acc_tab,ext_tab);
        
        % Delete extensions that already appear in figbass.
        idx = [];
        for j = 1:size(tab,1)
            idx = [idx; ismember(tab(j,:),figbass(j))];
        end
        tab(idx==1) = {''};
            
        % Create final changes variable.
        tab = join(tab);
        changes = strrep(tab,' ','');
        
        % Delete -7 in changes if 7 appears in figbass.
        idx = find(ismember(figbass,'7') & contains(changes,'-7'));
        changes(idx) = erase(changes(idx),'-7');
        
        % Concatenate chord tokens.
        tokens = strcat(root_RNs,forms,figbass,'(',changes,')');
        tokens = erase(tokens, {'()' ':'});

        clear key_onsets onsets roots remain keys_idx roots_idx root_nums forms ext inv ...
              changes t ext_tab acc_tab tmp tab idx idx2 p_idx idxrep
    else
        tokens = {};
        root_RNs = {};
    end
    
    % Create structure.
    Billboard.chords.(fnames{i}) = strcat(chords,', key=',keys);
    Billboard.RNs.(fnames{i}) = tokens;
    Billboard.rootRNs.(fnames{i}) = root_RNs;
    clear tokens root_RNs chords keys
end

% Delete songs with no chord annotations. 
for i=1:len
    sequence.(fnames{i}) = cellstr(Billboard.RNs.(fnames{i}));
end
fnames = fieldnames(sequence);
idx = cellfun(@(x) isempty(sequence.(x)), fnames);
sequence = rmfield(sequence, fnames(idx));
Billboard.RNs = rmfield(Billboard.RNs, fnames(idx));
Billboard.rootRNs = rmfield(Billboard.rootRNs, fnames(idx));
Billboard.chords = rmfield(Billboard.chords, fnames(idx));
fnames(idx) = [];

% Alphabet
chords = cellfun(@(x) cellstr(sequence.(x)), fnames, 'UniformOutput', false);
alphabet = unique(vertcat(chords{:}));
Billboard.fnames = fnames;
Billboard.alphabet = alphabet;

% Get year of composition for fnames.
tmp = erase(fnames,'Billboard_');
tmp = str2double(tmp);
songs = song_info.data(:,1);
songs = str2double(songs);
[~,idx] = ismember(tmp,songs);
year = song_info.year(idx);
Billboard.year = year;

%% EXPORT

cd('<destination_file_path>')
save('Billboard.mat','Billboard')


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
   