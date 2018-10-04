module VexFlow.Score (Stave, addTimeSignature, displayMusics, displayStave, initialise, newStave) where

import Data.Either (Either(..))
import Data.Abc (KeySignature, Music)
import Effect (Effect)
import Prelude (Unit, pure, unit)
import VexFlow.Abc.Stringify (keySignature, musics) as Stringify
import VexFlow.Types (AbcContext, Config, NoteSpec, StaveConfig, TimeSignature)


-- | a stave
foreign import data Stave :: Type

addTimeSignature :: Stave -> TimeSignature -> Effect Unit
addTimeSignature stave timeSignature =
  timeSignatureImpl stave timeSignature

newStave :: StaveConfig -> KeySignature -> Effect Stave
newStave staveConfig ks =
  newStaveImpl staveConfig (Stringify.keySignature ks)

{-}
displayNotes :: AbcContext -> Boolean -> Stave -> Array AbcNote -> Effect Unit
displayNotes abcContext isAutoBeam stave abcNotes =
  let
    eNotes = Stringify.notes abcContext abcNotes
  in
    case eNotes of
      Right notes ->
        if (isAutoBeam) then
          displayAutoBeamedNotesImpl abcContext stave  notes
        else
          displayNotesImpl stave notes
      _ ->
        pure unit
-}

displayMusics :: AbcContext -> Boolean -> Stave -> Array Music -> Effect Unit
displayMusics abcContext isAutoBeam stave abcMusics =
  let
    eNotes = Stringify.musics abcContext abcMusics
  in
    case eNotes of
      Right notes ->
        if (isAutoBeam) then
          displayAutoBeamedNotesImpl abcContext stave  notes
        else
          displayNotesImpl stave notes
      _ ->
        pure unit


foreign import initialise :: Config -> Effect Unit
foreign import newStaveImpl :: StaveConfig -> String -> Effect Stave
foreign import displayNotesImpl :: Stave -> Array NoteSpec -> Effect Unit
foreign import displayAutoBeamedNotesImpl :: AbcContext -> Stave -> Array NoteSpec -> Effect Unit
foreign import displayStave :: Stave -> Effect Unit
foreign import timeSignatureImpl :: Stave -> TimeSignature -> Effect Unit
