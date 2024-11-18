{$I COMPILER.INC}
unit VeriCons;

interface

type
  TScreenPosition = (spAbsolute, spRelative);

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


implementation

end.