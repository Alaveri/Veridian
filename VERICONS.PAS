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

  { Tags used by system, don't use }
  SystemTag = MaxInt - 256;


implementation

end.