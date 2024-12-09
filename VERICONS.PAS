{$I COMPILER.INC}
unit VeriCons;

interface

const
  DefaultWordDelimiters = [
    ' ', '.', '(', ')', '[', ']', '{', '}', ',','/','<', '>','?', '/', ':',
    '"', '''', ';', '-', '+', '-', '|', '\', '!'
  ];
  Aplpha = ['A'..'Z', 'a'..'z'];
  AlphaNumeric = ['0'..'9', 'A'..'Z', 'a'..'z'];
  Numeric = ['0'..'9'];
  Puncuation = ['.', ',', ';', ':', '!', '?', '"', '''', '(', ')', '[', ']',
    '{', '}', '/', '\', '|', '-', '+', '=', '*', '&', '^', '%', '$', '#',
    '@', '~', '`', '<', '>'
  ];
  Hexadecimal = ['0'..'9', 'A'..'F', 'a'..'f'];

  { Standard Veridian message Ids, don't use. }
  wmVeridian = $F000;
  vmMinimize = wmVeridian + 1;
  vmMaximize = wmVeridian + 2;
  vmRestore = wmVeridian + 3;
  vmClose = wmVeridian + 4;

  { Standard Veridian action Ids, don't use. }
  acVeridian = $FFFF - $1000;
  acVeridianDialog = acVeridian + $0100;

implementation

end.