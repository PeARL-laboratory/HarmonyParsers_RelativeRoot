# HarmonyParsers_RelativeRoot

   Harmony Parsers for the Relative Root Encoding Scheme


      PARSE -- Relative Root Representation 

         Encoding:    <RN><Quality><Inversion><Extensions>
   
            RN         -- Roman numeral encoded in relation to the key. Case
                          denotes quality of the triad (major or minor).
                          Named chords (+6, Ct, etc.) are converted to RN roots,
                          with the names included in the quality slot (e.g., 
                          #ivGer). Applied dominants (e.g., V/ii) receive 
                          diatonic equivalents. Chords may also be preceded by a
                          chromatic accidental relative to the major scale 
                          (e.g., viio/V --> #ivo):
                              --  double flat
                               -  flat 
                               #  sharp
                              ##  double sharp
   
           Quality    -- Chord quality: 
                               M  major seventh 
                                  minor seventh (no symbol)
                               d  major RN with minor seventh 
                               h  half-diminished seventh
                               o  diminished triad or seventh
                               +  augmented
                               p  power (i.e., no 3rd) 
                             Ger  German augmented sixth
                              Fr  French augmented sixth 
                              It  Italian augmented sixth
                              Ct  Common-tone diminished seventh
   
          Inversion  -- Chord inversion:
                                  root position (no symbol)
                               6  first inversion triad
                              64  second inversion triad
                               7  root position seventh
                              65  first inversion seventh
                              43  second inversion seventh
                              42  third inversion seventh 
   
          Extensions -- Suspensions or added tones appear in parentheses, with
                        added tones preceded by '+'.

          Example:     V(64) (i.e., a cadential six-four)
