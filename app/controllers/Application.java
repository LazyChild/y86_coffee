package controllers;


import play.Logger;
import play.Play;
import play.api.mvc.Action;
import play.api.mvc.AnyContent;
import play.mvc.Controller;
import play.mvc.Result;
import views.html.index;

public class Application extends Controller {
  
    public static Result index() {
        return ok(index.render());
    }

    public static Action<AnyContent> javascripts(String file) {
        String folder = "javascripts/";
        if (Play.isProd()) {
            folder = "javascripts-min/";
        }

        Logger.debug(String.format("[%s mode] JavaScript file '%s' served from '%s'.",
                Play.isProd() ? "prod" : "dev", file, folder + file));

        return controllers.Assets.at("/public", folder + file).apply();
    }
}
