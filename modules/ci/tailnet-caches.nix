{
  modules.ci.binaryCache = {
    enable = true;
    caches = [
      {
        url = "https://framework.cat-vimba.ts.net:8444/framework";
        publicKey = "framework:aokj6plTVRAfp1W2E3qILGF9TOY1z5AigXSCckogdCs=";
        priority = 41;
      }
      {
        url = "https://omega.cat-vimba.ts.net:8444/omega";
        publicKey = "omega:IPYhXc7nLy+PpzRqYHk1MWcxF97/Y8kCV/t1p6IE6Fw=";
        priority = 42;
      }
    ];
  };
}
