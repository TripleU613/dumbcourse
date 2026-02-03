import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings?.dumbcourse_sidebar_link_enabled) {
    return;
  }

  api.addSidebarSection(
    (BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
      class DumbcourseLink extends BaseCustomSidebarSectionLink {
        name = "dumbcourse";
        linkDragCss = "raw-link";
        text = i18n("dumbcourse.sidebar_link_text");
        title = i18n("dumbcourse.sidebar_link_title");
        href = getURL("/dumb");
        prefixValue = "link";
      }

      return class DumbcourseSection extends BaseCustomSidebarSection {
        name = "dumbcourse";
        text = i18n("dumbcourse.sidebar_section_title");
        title = i18n("dumbcourse.sidebar_section_title");
        hideSectionHeader = true;

        get links() {
          return [new DumbcourseLink()];
        }
      };
    }
  );
});
