%% Parse the chord symbols in the TAVERN data set using the Relative Root encoding scheme.
%
% *TAVERN DATA SET*
%
%   Download: <https://github.com/jcdevaney/TAVERN>
%   Citation: J. Devaney, C. Arthur, N. Condit-Schultz, and K. Nisula. 
%             Theme and variation encodings with roman numerals (TAVERN): A 
%             new data set for symbolic music analysis. In Proceedings of 
%             the International Society of Music Information Retrieval 
%             conference , pages 728–34, 2015.
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
%                        M  major seventh (never annotated in this data
%                           set)
%                           minor seventh (no symbol)
%                        d  major RN with minor seventh 
%                        h  half-diminished seventh
%                        o  diminished triad or seventh
%                        +  augmented
%                        p  power (i.e., no 3rd) (never annotated in this
%                           data set)
%                      Ger  German augmented sixth
%                       Fr  French augmented sixth (never annotated in this
%                           data set)
%                       It  Italian augmented sixth
%                       Ct  Common-tone diminished seventh
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


%% IMPORT & PREPROCESS

composers = {'Beethoven' 'Mozart'};
fnames_tot = [];
for g = 1:length(composers)

    % Import files.
    cd(strcat('<file_path>\TAVERN\TAVERN-master\',(composers{g})))
    files = dir;
    files = files(~ismember({files.name},{'.','..'}));
    fnames = {files.name}';

    for i = 1:length(fnames)

        % Annotations from Encoder B (analyzed all movements).
        cd(strcat('<file_path>\TAVERN\TAVERN-master\',(composers{g}),'\',(fnames{i}),'\Encodings\Encoder_B'))

        files = dir('*.krn');
        seg_names = {files.name}';

        seg_chords = [];
        seg_modes = [];
        for j = 1:length(seg_names)

            % import file
            [~,~,tmp] = tsvread(seg_names{j});

            % Delete comments and fill empty lines (for later code).
            idx = contains(tmp(:,1),'!!');
            tmp(idx,:) = [];
            idx = cellfun(@isempty,tmp);
            tmp(idx) = {'blank'};
            
            % Get RNs.
            [~,col] = find(contains(tmp,{'*harm' '*chords'}));
            seq = char(tmp(:,col));
            seq = seq(:,1);
            chord_idx = find(contains(cellstr(seq),cellstr(num2str([0:9]'))));
            chords = char(tmp(chord_idx,col));
            idx = isstrprop(chords,'alpha');
            [~,idx] = max(idx,[],2);
            newchords = cell(size(chords,1),1);
            for k = 1:size(chords,1)
                newchords(k,1) = cellstr(chords(k,idx(k):end)); % delete numbers at start of each chord.
            end
            chords = newchords;
            
            % Delete non-functional harmony tokens (see humdrum *harm help)
            idx = find(ismember(chords,{'D' 'P' 'r' '.' 'T'})); % 'T' is a bug. 
            chords(idx) = [];
            chord_idx(idx) = [];
            
            % Delete parentheses (implied harmonies are treated as harmonies)
            chords = erase(chords,{'(' ')'});
            
            % tokenize chord tokens with two chords (e.g., 'I IV/V'; bug in TAVERN)
            idx = find(contains(chords,{' '}));
            chord_idx = [chord_idx(1:idx); chord_idx(idx); chord_idx(idx+1:end)];
            chords = split(strjoin(chords));
            
            chords = erase(chords,'.'); % get rid of '.' in chords.

            % Get modes.
            mode_idx = find(contains(tmp(:,col),':'));
            if isempty(mode_idx) % bug in TAVERN; not all movements have key annotations
                maj = find(strcmp(chords,'I'),1,'last');
                if ~isempty(maj)
                    mode2(1:length(chords),1) = {'major'};
                else
                    mode2(1:length(chords),1) = {'minor'};
                end
            else
                mode = char(tmp(mode_idx,1));
                idx = isstrprop(mode,'alpha');
                [~,idx] = max(idx,[],2);
                mode = mode(idx);
                proper = isstrprop(mode,'upper');
                mode = cellstr(mode);
                mode(proper) = {'major'};
                mode(~proper) = {'minor'};
                for k = 1:length(mode)
                    mode2(chord_idx > mode_idx(k),1) = mode(k);
                end
            end

            % Concatenate segments for each movement.
            seg_chords = [seg_chords; chords];
            seg_modes = [seg_modes; mode2];

            clear tmp idx seq chord_idx chords mode_idx mode proper mode2
        end

        % Add to structure.
        TAVERN.chords.(fnames{i}) = seg_chords;
        TAVERN.mode.(fnames{i}) = seg_modes;
    end
    fnames_tot = [fnames_tot; fnames];
    clear files fnames
end
fnames = fnames_tot;
TAVERN.fnames = fnames;


%% CONVERT (relative root representation)

% Variables
RNs = {'--IV' '--I' '--V' '--II' '--VI' '--III' '--VII'  ...
       '-IV' '-I' '-V' '-II' '-VI' '-III' '-VII'  ...
       'IV' 'I' 'V' 'II' 'VI' 'III' 'VII'  ...
       '#IV' '#I' '#V' '#II' '#VI' '#III' '#VII' ...
       '##IV' '##I' '##V' '##II' '##VI' '##III' '##VII'}; 

% relative root encoding.
for i = 1:length(fnames)
    
    % Get chords.
    chords = TAVERN.chords.(fnames{i});
    
    % Replace flat symbol for roots ('b' must precede root).
    chords = replace(chords,{'bI' 'bi' 'bV' 'bv'},{'-I' '-i' '-V' '-v'});
    
    % Ct should be consistent. 
    chords = replace(chords,{'ct' 'CT'},'Ct');
    
    % Replace symbols related to inversions and seventh chords.
    chords = replace(chords,'@','h');
    chords = replace(chords,'om','h'); % half-diminished sevenths 
    chords = replace(chords,'hb','h65'); % half-diminished 65
    chords = replace(chords,'b9','7(-9)'); % flat 9
    chords = replace(chords,'7b', '65');
    idx = find(strcmp(cellstr(cellfun(@(v) v(end), chords)),'b')); % find last element = b, which means first inversion in the Humdrum scheme.
    chords(idx) = replace(chords(idx),'b','6');
    chords = replace(chords,'7c','43');
    chords = replace(chords,'11c','43(11)'); % one instance of an 11th chord.
    chords = replace(chords,'c','64');
    chords = replace(chords,'7d','42');
    chords = replace(chords,'d','42');
    chords = replace(chords,'2','42');
    chords = replace(chords,'442','42');
    
    % N should be -II.
    chords = replace(chords,'N','-II');
    
    % Replace symbols related to extensions.
    chords = replace(chords,'V9','V7(9)');
    
    % cadential six-four annotated as I64 (bug).
    if ~any(find(contains(chords,{'C64' 'c64' 'Cc'}))) & any(find(contains(chords,{'I64' 'i64' 'Ic' 'ic'})))
        idx = find(startsWith(chords,{'I64' 'i64' 'Ic' 'ic'}));
        tmp = [chords(idx) chords(idx+1)];
        change = startsWith(tmp(:,2),{'V7(' 'V(' 'V7/' 'V/'}) | ismember(tmp(:,2),{'V' 'V7'});
        
        relroot = extractAfter(tmp,'/'); % Don't change to V(64) if both chords aren't applied to the same key (e.g., V(64)/IV V7/IV).
        idx2 = strcmp(relroot(:,1),relroot(:,2));
        change = find(change+idx2==2);
        
        tmp = tmp(:,1);
        relroot = extractAfter(tmp,'/');
        relroot = strcat('/',relroot);
        relroot(strcmp(relroot,'/')) = {''};
        
        tmp(change) = {'V(64)'};
        tmp(change) = strcat(tmp(change),relroot(change));
        chords(idx) = tmp;
    end
    
    % cadential six-four annotated with humdrum encodings.
    chords = replace(chords,{'Cc' 'C64'},'V(64)'); 
    
    % V56 should be V65 (bug)
    chords = replace(chords,'56','65');
    
    % Revise chords with non-root RN labels (e.g., +6, Ct).
    form = chords;
    figbass = chords;
    chords = replace(chords,'it','It'); % make 'It' annotation consistent (bug).
    idx = find(contains(chords,'It'));
    form(idx) = {'It'};
    chords(idx) = {'#iv'};
    figbass(idx) = {''};
    idx = find(contains(chords,'Fr'));
    form(idx) = {'Fr'};
    chords(idx) = {'II'};
    figbass(idx) = {''};
    idx = find(contains(chords,'Gr'));
    form(idx) = {'Ger'};
    chords(idx) = {'#iv'};
    figbass(idx) = {''};
    
    % Replace Ct chords with #iio42.
    idx = find(contains(chords,'Ct'));
    form(idx) = {'Cto'};
    figbass(idx) = {'42'};
    chords = replace(chords,'Ct','#ii');
    chords(idx) = erase(chords(idx),'7');
    
    % Revise root, form, figbass, changes, and relroot.
    root = erase(chords,{'(' ')' '1' '2' '3' '4' '5' '6' '7' '9' 'b' '+' 'o' 'h'});
    idx = find(contains(root,'/'));
    root(idx) = extractBefore(root(idx),'/');
    root = replace(root,{'I-' 'i-' 'V-' 'v-'},{'I' 'i' 'V' 'v'});
    
    form = erase(form,{'-' '#' 'I' 'i' 'V' 'v' '(' ')' '/' '1' '2' '3' '4' '5' '6' '7' '9' 'b'});
    idx = find(strcmp(form,'t'));
    form(idx) = {'It'}; 
    
    idx = find(contains(figbass,{'(' ')'}));
    figbass(idx) = eraseBetween(figbass(idx),'(',')');
    figbass = erase(figbass,{'-' '#' 'Ct' 'I' 'i' 'V' 'v' '(' ')' '/' 'b' '+' 'o' 'h'});
    
    changes = cell(length(chords),1);
    idx = find(contains(chords,{'(' ')'}));
    changes(idx) = extractBetween(chords(idx),'(',')');
    
    % Count number of relative roots in chords (e.g., V/V/V).
    ct = strfind(chords,'/'); 
    ct = max(cell2mat(cellfun(@length,ct,'uni',false)));
    
    if ct > 0
       
        relroot = cell(length(chords),ct);
        relroot(:,1) = extractAfter(chords,'/');
        if ct == 2
            relroot(:,2) = extractAfter(relroot(:,1),'/');
            idx = find(contains(relroot(:,1),'/'));
            relroot(idx,1) = extractBefore(relroot(idx,1),'/');
        end
    
        % Convert applied chords to diatonic space.
        applied_idx = find(contains(chords,'/')); 
            
        rel_roots = [root relroot];
        rel_roots = rel_roots(applied_idx,:);

        idx = find(cellfun(@isempty,rel_roots(:,end)));
        rel_roots(idx,:) = circshift(rel_roots(idx,:),1,2);

        for j = ct:-1:1

            % Create numerator and denominator of applied chords.
            num = rel_roots(:,j);
            den = rel_roots(:,j+1);
            roots_idx = find(~cellfun(@isempty,num));
            num = num(roots_idx);
            den = den(roots_idx);

            % Determine relative root for applied chords.
            [~,den_idx] = ismember(upper(den),RNs);
            [~,num_idx] = ismember(upper(num),RNs);
            [~,tonic_idx] = ismember('I',RNs);

            root_idx = mod(num_idx-tonic_idx + den_idx,length(RNs));
            roots = [RNs(root_idx)]';

            % Ensure relative root reflects quality of numerator chord.
            idx = isstrprop(num,'upper');
            for k = 1:length(idx)
                if any(idx{k})==1
                    idx2(k,1) = 1;
                else idx2(k,1) = 0;
                end
            end
            idx = idx2;
            roots(idx==0) = lower(roots(idx==0));
            rel_roots(roots_idx,j) = roots;
            rel_roots(:,j+1) = [];
            roots_fin(roots_idx,1) = roots;
            
            clear den num roots_idx den_idx num_idx tonic_idx root_idx roots idx idx2 roots 

        end

        % Include 'd' to form if root RN is major and has a seventh.
        idx = isstrprop(roots_fin,'upper');
        for k = 1:length(idx)
            if any(idx{k})==1
                idx2(k,1) = 1;
            else idx2(k,1) = 0;
            end
        end
        idx = idx2;
        RN_maj = find(idx==1);
        relroot_7th = find(ismember(figbass(applied_idx),{'7' '65' '43' '42'}));
        d7 = intersect(RN_maj,relroot_7th);
        form(applied_idx(d7)) = {'d'};
        root(applied_idx) = roots_fin;
        
        clear roots_fin applied_idx idx idx2 RN_maj relroot_7th d7
    end
    
    % Fix bug that adds a '7' to the figbass symbol for 7b9 chords.
    figbass = replace(figbass,'77','7');
    
    % Add to structure.
    tmp = strcat(root,form,figbass,'(',changes,')');
    tmp = replace(tmp,'()','');
    
    if any(strcmp(tmp,'Vd42'))
        idx = find(strcmp(tmp,'Vd42'));
    end
    
    TAVERN.RNs.(fnames{i}) = tmp; % RNs
    TAVERN.rootRNs.(fnames{i}) = strcat(root,form); % RN roots
    clear tmp chords root form figbass changes relroot mode idx
end

% Include alphabet of RN types.
fnames = TAVERN.fnames;
for i = 1:length(fnames)
    seq.(fnames{i}) = cellstr(TAVERN.RNs.(fnames{i}));
end
chords = cellfun(@(x) cellstr(seq.(x)), fnames, 'UniformOutput', false);
alphabet = unique(vertcat(chords{:}));
TAVERN.alphabet = alphabet;


%% EXPORT

cd('<destination_file_path>')
save('TAVERN.mat','TAVERN')





