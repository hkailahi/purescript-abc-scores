"use strict";

var wrapper = function() {

  var VF = null;
  var renderer = null;
  var context = null;

  return {

    initialiseCanvas : function (config) {
      return function () {
        return wrapper.init(config);
      }
    },

    clearCanvas : function () {
      context.clear();
    },

    newStaveImpl : function (staveConfig) {
      return function (keySignature) {
        return function () {
          return wrapper.makeStave(staveConfig, keySignature);
        }
      }
    },

    displayBarBeginRepeat : function (stave) {
      return function () {
        stave.setBegBarType(VF.Barline.type.REPEAT_BEGIN);
      }
    },

    displayBarEndRepeat : function (stave) {
      return function () {
        stave.setEndBarType(VF.Barline.type.REPEAT_END);
      }
    },

    displayBarBothRepeat : function (stave) {
      return function () {
        stave.setBegBarType(VF.Barline.type.REPEAT_BEGIN);
        stave.setEndBarType(VF.Barline.type.REPEAT_END);
      }
    },

    displayVolta : function (stave) {
      return function (volta) {
        return function () {
          return wrapper.drawVolta(stave, volta);
        }
      }
    },

    displayStave : function (stave) {
      return function () {
        return wrapper.drawStave(stave);
      }
    },

    getStaveWidth : function (stave) {
      return function () {
        return stave.getWidth();
      }
    },

    addTimeSignature : function (stave) {
      return function (timeSignature) {
        return function () {
          return wrapper.drawTimeSignature(stave, timeSignature);
        }
      }
    },

    addKeySignature : function (stave) {
      return function (keySignature) {
        return function () {
          return wrapper.drawKeySignature(stave, keySignature, false);
        }
      }
    },

    addTempoMarkingImpl : function (stave) {
      return function (tempo) {
        return function () {
          return wrapper.drawTempoMarking(stave, tempo);
        }
      }
    },

    displayBarContents : function (stave) {
      return function (beamGroups) {
        return function (vexCurves) {
          return function (musicSpec) {
            return function () {
              return wrapper.drawBarContents(stave, beamGroups, vexCurves, musicSpec);
            }
          }
        }
      }
    },

    init: function (config) {
      // console.log(config);

      VF = Vex.Flow;
      renderer = new VF.Renderer(config.canvasDivId , VF.Renderer.Backends.SVG);
      // renderer = new VF.Renderer(config.canvasDivId, VF.Renderer.Backends.CANVAS);

      // Size our svg:
      renderer.resize(config.canvasWidth, config.canvasHeight);

      context = renderer.getContext();
      context.scale(config.scale, config.scale);
    },

    makeStave: function (staveConfig, keySignature) {

      var staveOptions = new Object();
      staveOptions.right_bar = staveConfig.hasRightBar;

      // Create a stave at the required position on the canvas.
      var stave = new VF.Stave(staveConfig.x, staveConfig.y, staveConfig.width, staveOptions);

      // create a doubled right bar line if required
      if (staveConfig.hasDoubleRightBar) {
         stave.setEndBarType(VF.Barline.type.DOUBLE);
      }

      // Add a clef and key signature if it's the first bar in the stave
      if (staveConfig.barNo == 0) {
        wrapper.drawKeySignature (stave, keySignature, true);
      }

      return stave;
    },

    drawStave: function (stave) {
      stave.setContext(context).draw();
    },

    drawTimeSignature: function (stave, timeSignature) {
      var meter = timeSignature.numerator + "/" + timeSignature.denominator;
      stave.setTimeSignature(meter);
    },

    drawVolta: function (stave, volta) {
      // console.log("volta:")
      // console.log(volta);
      var voltaType;
      switch(volta.voltaType) {
        case 2:
          voltaType = VF.Volta.type.BEGIN;
          break;
        case 3:
          voltaType = VF.Volta.type.MID;
          break;
        case 4:
          voltaType = VF.Volta.type.END;
          break;
        case 5:
          voltaType = VF.Volta.type.BEGIN_END;
          break;
        default:
          voltaType = VF.Volta.type.NONE;
      }
      stave.setVoltaType(voltaType, volta.iteration, 30);
    },

    drawKeySignature: function (stave, keySignature, withClef) {
      if (withClef) {
        stave.addClef("treble");
      }
      stave.setKeySignature(keySignature);
    },

    drawTempoMarking: function (stave, tempo) {
      stave.setTempo(tempo, 0);
    },

    /* draw the contents of the bar, using auto-beaming for the notes */
    drawBarContents: function (stave, beamGroups, vexCurves, musicSpec) {
      // console.log("drawBarContents")
      // console.log(musicSpec);
      var notes = musicSpec.noteSpecs.map(wrapper.makeStaveNote);
      var tuplets = musicSpec.tuplets.map(wrapper.makeTupletLayout (notes));
      var ties = musicSpec.ties.map(wrapper.makeTie (notes));
      var groups = beamGroups.map(wrapper.beamGroup);
      var beams = VF.Beam.generateBeams(notes, { groups : groups } );
      var curves = vexCurves.map(wrapper.makeCurve (notes));

      Vex.Flow.Formatter.FormatAndDraw(context, stave, notes);
      beams.forEach(function(b) {b.setContext(context).draw()});
      ties.forEach(function(t) {t.setContext(context).draw()})
      tuplets.forEach(function(tuplet){
        tuplet.setContext(context).draw();
      });
      curves.forEach(function(c) {c.setContext(context).draw()});
    },


    // make a stave note (n.b. this can represent a single note or a chord)
    makeStaveNote: function (noteSpec) {
      var sn = new VF.StaveNote(noteSpec.vexNote);
      wrapper.addAccidentals (sn, noteSpec.accidentals);
      wrapper.addDots (sn, noteSpec.dots);
      wrapper.addOrnaments (sn, noteSpec.ornaments);
      wrapper.addArticulations (sn, noteSpec.articulations);

      if (noteSpec.graceKeys.length > 0) {
        var graceNotes = noteSpec.graceKeys.map(wrapper.makeGraceNote);
        var graceNoteGroup =  new VF.GraceNoteGroup(graceNotes, true);
        sn.addModifier(0, graceNoteGroup.beamNotes());
      }
      return sn;
    },

    makeGraceNote: function (graceKey) {
      var note = { keys: [graceKey], duration: '8' };
      return new Vex.Flow.GraceNote (note);
    },

    // make a tuplet layout
    makeTupletLayout: function (notes) {
      return function (vexTuplet) {
        return new Vex.Flow.Tuplet(notes.slice(vexTuplet.startPos, vexTuplet.endPos), {
           num_notes: vexTuplet.p, notes_occupied: vexTuplet.q
         });
      };
    },

    // tie a note to its successor
    makeTie: function (notes) {
      return function (noteIndex) {
        return new VF.StaveTie({
          first_note: notes[noteIndex],
          last_note: notes[noteIndex + 1],
          first_indices: [0],
          last_indices: [0]
        });
      };
    },

    // auto-beaming definition of one beam group
    beamGroup: function (group) {
      return new Vex.Flow.Fraction(group.noteCount, group.noteKind);
    },

    // make a slur represented by a curve
    makeCurve: function (notes) {
      return function (vexCurve) {
        return new VF.Curve(
          notes[vexCurve.from],
          notes[vexCurve.to],
          { cps: [{ x: 0, y: 10 }, { x: 0, y: 20 }]
        });
      };
    },

    // add the accidental(s) to the staveNote
    addAccidentals: function (staveNote, accidentals) {
      accidentals.forEach (function (accidentalString, index) {
        if (accidentalString) {
          staveNote.addAccidental(index, new VF.Accidental(accidentalString));
        }
      });
    },

    // add the accidental(s) to the staveNote(s)
    addDots: function (staveNote, dots) {
      dots.forEach (function (dotCount, index) {
        if (dotCount == 2) {
          staveNote.addDot(index).addDot(index);
        }
        else if (dotCount == 1) {
          staveNote.addDot(index);
        }
      });
    },

    // add the ornamant(s) to the staveNote
    addOrnaments: function (staveNote, ornaments) {
      ornaments.forEach (function (ornament, index) {
        staveNote.addModifier(0, new VF.Ornament(ornament));
      });
    },

    // add the articulation(s) to the staveNote
    addArticulations: function (staveNote, articulations) {
      articulations.forEach (function (articulation, index) {
        staveNote.addArticulation(0, new VF.Articulation(articulation));
      });
    }

  }

}();

exports.initialiseCanvas = wrapper.initialiseCanvas;
exports.clearCanvas = wrapper.clearCanvas;
exports.newStaveImpl = wrapper.newStaveImpl;
exports.displayStave = wrapper.displayStave;
exports.getStaveWidth = wrapper.getStaveWidth;
exports.displayBarBeginRepeat = wrapper.displayBarBeginRepeat;
exports.displayBarEndRepeat = wrapper.displayBarEndRepeat;
exports.displayBarBothRepeat = wrapper.displayBarBothRepeat;
exports.displayBarContents = wrapper.displayBarContents;
exports.displayVolta = wrapper.displayVolta;
exports.addTimeSignature = wrapper.addTimeSignature;
exports.addKeySignature = wrapper.addKeySignature;
exports.addTempoMarkingImpl = wrapper.addTempoMarkingImpl;
