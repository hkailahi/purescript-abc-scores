module VexFlow.Types where

import Data.Abc (BarType, NoteDuration, KeySignature)
import Data.Either (Either)
import Data.Maybe (Maybe)
import Prelude (class Eq, class Monoid, class Semigroup, mempty, (<>))
import VexFlow.Abc.ContextChange (ContextChange)
import VexFlow.Abc.TickableContext (TickableContext)
import VexFlow.Abc.Volta (Volta)
import VexFlow.Abc.Slur (SlurBracket, VexCurve)

-- | the indentation of the stave from the left margin
staveIndentation :: Int
staveIndentation = 10

-- | the margin above and below the score
scoreVerticalMargin :: Int
scoreVerticalMargin = 15

-- | the distance between successive staves
staveSeparation :: Int
staveSeparation = 100

type VexScore = Either String (Array (Maybe StaveSpec))

-- | the configuration of the VexFlow Canvas
type Config =
    { canvasDivId :: String
    , canvasWidth :: Int
    , canvasHeight :: Int
    , scale :: Number
    }

-- | the configuration of a Stave
type StaveConfig =
    { x :: Int
    , y :: Int
    , width :: Int
    , barNo :: Int
    , hasRightBar :: Boolean
    , hasDoubleRightBar :: Boolean
    }

-- | the time signature
type TimeSignature =
  { numerator :: Int
  , denominator :: Int
  }

type VexDuration =
  { vexDurString :: String   -- w,h,q,8,16 or 32
  , dots :: Int              -- number of dots
  }

-- | the tempo marking
type Tempo =
  { duration :: String
  , dots :: Int
  , bpm :: Int
  }

-- | The ABC Context
type AbcContext =
  { timeSignature :: TimeSignature
  , keySignature :: KeySignature
  , mTempo :: Maybe Tempo
  , unitNoteLength :: NoteDuration
  , staveNo :: Maybe Int
  , accumulatedStaveWidth :: Int
  , isMidVolta :: Boolean            -- we've started but not finished a volta
  , isNewTimeSignature :: Boolean    -- we need to display a changed time signature
  , maxWidth :: Int
  , pendingRepeatBegin :: Boolean    -- begin repeat to be prepended to next stave
  }

type NoteSpec =
  { vexNote :: VexNote
  , accidentals :: Array String
  , dots :: Array Int
  , graceKeys :: Array String
  , ornaments :: Array String
  , articulations :: Array String
  }

-- | A raw note that VexFlow understands
type VexNote =
  { clef :: String
  , keys :: Array String
  , duration :: String
  }

-- | the specification of the layout of an individual tuplet in the stave
type VexTuplet =
  { p :: Int           -- fit p notes
  , q :: Int           -- into time allotted to q
  , startPos :: Int    -- from the array of notes at this position..
  , endPos :: Int      -- to this position
  }

-- | the specification of an individual tuplet
type TupletSpec =
  { vexTuplet :: VexTuplet
  , noteSpecs :: Array NoteSpec
  }

-- | a beam group
type BeamGroup =
  { noteCount :: Int -- how many notes of the kind inhabit the group
  , noteKind  :: Int -- the kind of note is the denominator of the time signature
  }

type BeamGroups = Array BeamGroup

-- | the specification of a music item or a bar of same
-- | we may just have note specs in either or we may have
-- | one tuple spec (in the case of a single tupinstance
-- | or many (in the case of a full bar of music items)
newtype MusicSpec = MusicSpec MusicSpecContents

instance musicSpecSemigroup :: Semigroup MusicSpec  where
  append (MusicSpec ms1) (MusicSpec ms2) =
    MusicSpec (ms1 <> ms2)

instance musicSpecMonoid:: Monoid MusicSpec where
  mempty = MusicSpec
    { noteSpecs : mempty
    , tuplets : mempty
    , ties : mempty
    , tickableContext : mempty
    , contextChanges : mempty
    , midBarNoteIndex : mempty
    , slurBrackets : mempty
    }

data LineThickness =
    Single
  | Double
  | NoLine

derive instance eqLineThickness :: Eq LineThickness

-- | we define MusicSpecContents separately from MusicSpec
-- | because we need to pass it to JavaScript
type MusicSpecContents =
  { noteSpecs :: Array NoteSpec
  , tuplets :: Array VexTuplet
  , ties :: Array Int
  , tickableContext :: TickableContext
  , contextChanges :: Array ContextChange
  , midBarNoteIndex  :: Array Int      -- note index (if any) at the bar midpoint
  , slurBrackets :: Array SlurBracket  -- brackets (L and R) demarking slurs
  }

type BarSpec =
  { barNumber :: Int
  , width  :: Int
  , xOffset :: Int
  , startLine :: BarType                  -- the Left bar line (always present)
  , endLineThickness :: LineThickness     -- right bar line type (default Single)?
  , endLineRepeat :: Boolean              -- does it have an end repeat? important for end repeat markers
  , volta :: Maybe Volta
  , timeSignature :: TimeSignature
  , beamGroups :: Array BeamGroup
  , curves :: Array VexCurve              --  curves representing slurs
  , musicSpec :: MusicSpec
  }

type StaveSpec =
  { staveNo :: Int
  , staveWidth :: Int               -- the cumulative width of the stave bars
  , keySignature :: KeySignature
  , isNewTimeSignature :: Boolean   -- do we need to display a time signature?
  , mTempo :: Maybe Tempo           -- the tempo marker
  , barSpecs :: Array BarSpec
  }
