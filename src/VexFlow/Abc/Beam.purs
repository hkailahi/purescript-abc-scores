module VexFlow.Abc.Beam (defaultBeamGroups) where

-- work out the beam groups from the time signature

import Prelude ((==), (-), (&&), map)
import Data.Array (length)
import VexFlow.Types (BeamGroups, MusicSpec(..), TimeSignature)

-- | set the default grouping of notes that are beamed together
-- | according to the meter signature and MusicSpec contents
-- | with 4/4 rhythms beamed differently according to the
-- | note index of the bar midpoint
defaultBeamGroups :: TimeSignature -> MusicSpec -> BeamGroups
defaultBeamGroups timeSignature (MusicSpec spec) =
  -- special-case 3/2 time signatures.  Here, the beat occupies a half note
  -- which doesn't attract much in the way of beaming unless you split it
  -- into qquarter notes
  if (timeSignature.numerator == 3) && (timeSignature.denominator == 2) then
    [ { noteCount: 1, noteKind: 4 }]
  -- otherwise the note kind is taken directly from the signature denominator
  else
    let
      noteKind =
        timeSignature.denominator
      noteCounts =
        case timeSignature.numerator of
          3 -> [1]
          4 ->
            case spec.midBarNoteIndex of
              [4] ->
                if (length spec.noteSpecs == 8) then
                  -- | AAAA AAAA |
                  [2]
                else
                -- for example | AAAA A2AA |
                  [2,1,1]
              [x] ->
              -- for example |  A2AA AAAA |
                if (length spec.noteSpecs - x == 4) then
                  [1,1,2]
                else
                  [1]
              _ ->
                [1]
          6 -> [3]
          9 -> [3]
          12 -> [3]
          _ -> [1]
    in
      map (\noteCount -> { noteCount, noteKind }) noteCounts
