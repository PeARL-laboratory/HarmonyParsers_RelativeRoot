%% Parse the chord symbols in the ABC data set using the Relative Root encoding scheme.
%
% *ABC DATA SET*
%
%   Download: <https://github.com/DCMLab/ABC>
%   Citation: Neuwirth, M., Harasim, D., Moss, F. C., & Rohrmeier, M. 
%             (2018). The Annotated Beethoven Corpus (ABC): A dataset of 
%             harmonic analyses of all Beethoven string quartets. Frontiers 
%             in Digital Humanities, 5(16). doi:10.3389/fdigh.2018.00016
%
%
% *PARSE -- Relative Root Representation* 
%
%   Encoding:    <RN><Quality><Inversion><Extensions>
%
%     RN         -- Roman numeral encoded in relation to the key. Case
%                   denotes quality of the triad (major or minor).
%                   Augmented sixth chords appear as 'Ger', 'Fr', and 'It'. 
%                   Applied dominants (e.g., V/ii) receive diatonic
%                   equivalents. Chords may also be preceded by a
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
%                        d  major RN with minor seventh 
%                        h  half-diminished seventh
%                        o  diminished triad or seventh
%                        +  augmented
%                        p  power (i.e., no 3rd) (never annotated in this
%                           data set)
%                      Ger  German augmented sixth
%                       Fr  French augmented sixth
%                       It  Italian augmented sixth
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
%   Time:          12:49	
%   Programmer:    David Sears	    
%   Version:       MATLAB 9.6 (R2019a, PC)


%% IMPORT

cd('<file_path>\ABC_dataset\ABC-master\ABC-master\data')
data = readtable('all_annotations.csv');


%% IMPORT & PREPROCESS

% Build chords with root RN, quality, inversion, changes, and relative root.
chords = strcat(data.numeral,data.form,data.figbass,'(',data.changes,')','/',data.relativeroot);

% Remove '()' symbol denoting no changes.
idx = find(cellfun(@isempty,data.changes));
chords(idx) = erase(chords(idx),'()');

% Remove '/' symbol denoting no relative root.
idx = find(cellfun(@isempty,data.relativeroot));
chords(idx) = erase(chords(idx),'/');

% Replace chord with pedal if pedal exists (i.e., ignore chords inside pedal).
idx = find(~cellfun(@isempty,data.pedal));
chords(idx) = data.pedal(idx);

% Correct annotations for chords inside pedal in data.
data.numeral(idx) = data.pedal(idx);
data.form(idx) = {''};
data.figbass(idx) = {''};
data.changes(idx) = {''};
data.relativeroot(idx) = {''};

% Replace half-diminished '%' with diminished 'o' symbol if there is no figbass symbol. (bug in ABC data set)
idx = find(strcmp(data.form,'%'));
idx2 = find(cellfun(@isempty,data.figbass));
idx = intersect(idx,idx2);
chords(idx) = replace(chords(idx),'%','o');
data.form(idx) = replace(data.form(idx),'%','o');

% Delete empty cells due to an uninterpretable chord '@none'.
idx = find(cellfun(@isempty,chords));
data(idx,:) = [];
chords(idx) = [];

% Determine mode of key for each chord.
local_key = data.local_key;
local_key = replace(local_key,'b','-');
idx = isstrprop(local_key,'upper');
for j = 1:length(idx)
    if all(idx{j})==1
        idx2(j,1) = 1;
    else idx2(j,1) = 0;
    end
end
idx = idx2;
mode(idx==1,1) = {'major'};
mode(idx==0,1) = {'minor'};

% Restructure so my analysis pipeline can recognize chord tokens from each movement.
fnames_tot = strcat('op',data.op,'_','no',data.no,'_','mv',data.mov);
fnames = unique(fnames_tot);
[~,idx] = ismember(fnames_tot,fnames);
for i = 1:length(fnames)
    tmp_idx = find(idx==i);
    sequence.chords.(fnames{i}) = chords(tmp_idx);
    sequence.RN.(fnames{i}) = data.numeral(tmp_idx);
    sequence.form.(fnames{i}) = data.form(tmp_idx);
    sequence.figbass.(fnames{i}) = data.figbass(tmp_idx);
    sequence.changes.(fnames{i}) = data.changes(tmp_idx);
    sequence.relroot.(fnames{i}) = data.relativeroot(tmp_idx);
    sequence.modes.(fnames{i}) = mode(tmp_idx);   
end


%% CONVERT (relative root representation)

% Variables
RNs = {'--IV' '--I' '--V' '--II' '--VI' '--III' '--VII'  ...
       '-IV' '-I' '-V' '-II' '-VI' '-III' '-VII'  ...
       'IV' 'I' 'V' 'II' 'VI' 'III' 'VII'  ...
       '#IV' '#I' '#V' '#II' '#VI' '#III' '#VII' ...
       '##IV' '##I' '##V' '##II' '##VI' '##III' '##VII'}; 

% relative root encoding.
for i = 1:length(fnames)
    
    % Variables.
    chords = sequence.chords.(fnames{i});
    root = sequence.RN.(fnames{i});
    form = sequence.form.(fnames{i});
    figbass = sequence.figbass.(fnames{i});
    changes = sequence.changes.(fnames{i});
    relroot = sequence.relroot.(fnames{i});
    mode = sequence.modes.(fnames{i});
    
    % Save raw chord tokens.
    ABC.chords.(fnames{i}) = chords;
    
    % Replace flat symbol for roots.
    root = replace(root,'b','-');
    relroot = replace(relroot,'b','-');
    changes = replace(changes,'b','-');
    
    % Replace % with h for diminished seventh chords.
    form = replace(form,'%','h');
    
    % Replace inversion 2 with 42.
    figbass = replace(figbass,'2','42');
    
    % Replace augmented 6th chords.
    idx = find(contains(root,'It'));
    form(idx) = {'It'};
    figbass(idx) = {''};
    root = replace(root,'It','#iv');
    
    idx = find(contains(root,'Fr'));
    form(idx) = {'Fr'};
    figbass(idx) = {''};
    root = replace(root,'Fr','II');
    
    idx = find(contains(root,'Ger'));
    form(idx) = {'Ger'};
    figbass(idx) = {''};
    root = replace(root,'Ger','#iv');
      
    % #vii should always be vii (they mean ^7, not ^#7).
    root = replace(root,'#vii','vii');
    root = replace(root,'#VII','VII');
    relroot = replace(relroot,'#vii','vii');
    relroot = replace(relroot,'#VII','VII');
    
    % III in minor should be -III
    idx = find(ismember(mode,'minor'));
    idx2 = find(ismember(root,'III'));
    idx = intersect(idx,idx2);
    root(idx) = strcat('-',root(idx));
    
    idx = find(ismember(mode,'minor'));
    idx2 = find(ismember(relroot,'III'));
    idx = intersect(idx,idx2);
    relroot(idx) = strcat('-',relroot(idx));
    
    % VI in minor should be -VI
    idx = find(ismember(mode,'minor'));
    idx2 = find(ismember(root,'VI'));
    idx = intersect(idx,idx2);
    root(idx) = strcat('-',root(idx));
    
    idx = find(ismember(mode,'minor'));
    idx2 = find(ismember(relroot,'VI'));
    idx = intersect(idx,idx2);
    relroot(idx) = strcat('-',relroot(idx));
    
    % VII in major or minor should be -VII
    idx = find(ismember(root,'VII'));
    root(idx) = strcat('-',root(idx));
    
    idx = find(ismember(relroot,'VII'));
    relroot(idx) = strcat('-',relroot(idx));
    
    % Treat all chord members beyond the 7th as extensions.
    idx = find(strcmp(figbass,'9'));
    figbass(idx) = {'7'};
    changes(idx) = strcat('9',changes(idx));
    
    % cadential six-four annotated as I64 (bug).
    if ~any(find(contains(chords,{'C64' 'c64' 'Cc'}))) & any(find(contains(chords,{'I64' 'i64' 'Ic' 'ic'})))
        idx = find(startsWith(chords,{'I64' 'i64' 'Ic' 'ic'}));
        tmp = [chords(idx) chords(idx+1)];
        change = startsWith(tmp(:,2),{'V7(' 'V(' 'V7/' 'V/'}) | ismember(tmp(:,2),{'V' 'V7'});
        
        relroots = extractAfter(tmp,'/'); % Don't change to V(64) if both chords aren't applied to the same key (e.g., V(64)/IV V7/IV).
        idx2 = strcmp(relroots(:,1),relroots(:,2));
        change = find(change+idx2==2);
        
        tmp = tmp(:,1);
        relroots = relroots(:,1);
        relroots = strcat('/',relroots);
        relroots(strcmp(relroots,'/')) = {''};
        
        tmp(change) = {'V(64)'};
        changes(idx(change)) = {'64'};
        figbass(idx(change)) = {''};
        root(idx(change)) = {'V'};
        relroot(idx(change)) = relroots(change);
        tmp(change) = strcat(tmp(change),relroots(change));
        chords(idx) = tmp;
    end
    
    % Convert applied chords to diatonic space.
    applied_idx = find(~cellfun(@isempty,relroot));    
    if ~isempty(applied_idx)

        % Create numerator and denominator of applied chords.
        num = root(applied_idx);
        den = relroot(applied_idx);

        % Determine relative root for applied chords.
        [~,den_idx] = ismember(upper(den),RNs);
        [~,num_idx] = ismember(upper(num),RNs);
        [~,tonic_idx] = ismember('I',RNs);
         
        root_idx = mod(num_idx-tonic_idx + den_idx,length(RNs));
        roots = [RNs(root_idx)]';

        % Ensure relative root reflects quality of numerator chord.
        idx = isstrprop(num,'upper');
        for j = 1:length(idx)
            if any(idx{j})==1
                idx2(j,1) = 1;
            else idx2(j,1) = 0;
            end
        end
        idx = idx2;
        roots(idx==0) = lower(roots(idx==0));

        % Include 'd' to form if root RN is major and has a seventh.
        RN_maj = find(idx==1);
        relroot_7th = find(ismember(figbass(applied_idx),{'7' '65' '43' '42'}));
        d7 = intersect(RN_maj,relroot_7th);
        form(applied_idx(d7)) = {'d'};
        root(applied_idx) = roots;
        
        clear applied_idx applied dom_idx num_1 den num den_idx num_idx tonic_idx root_idx roots idx roots idx2 RN_maj relroot_7th d7
    end
    
    % Add to structure.
    tmp = strcat(root,form,figbass,'(',changes,')');
    tmp = replace(tmp,'()','');
    
    ABC.RNs.(fnames{i}) = tmp; % RNs
    ABC.rootRNs.(fnames{i}) = strcat(root,form); % RN roots
    ABC.mode.(fnames{i}) = mode;
    clear tmp chords root form figbass changes relroot mode tot
end

% Include alphabet of RN types.
for i = 1:length(fnames)
    seq.(fnames{i}) = cellstr(ABC.RNs.(fnames{i}));
end
chords = cellfun(@(x) cellstr(seq.(x)), fnames, 'UniformOutput', false);
alphabet = unique(vertcat(chords{:}));
ABC.fnames = fnames;
ABC.alphabet = alphabet;


%% EXPORT

cd('<destination_file_path>')
save('ABC.mat','ABC');


