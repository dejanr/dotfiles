self: super:

{
  t = import ./t {
    inherit (super) stdenv writeScript;
  };
}
