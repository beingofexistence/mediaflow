# frozen_string_literal: true

module Features
  module DomHelpers
    def has_testid?(testid, **kwargs)
      page.has_selector?("[data-testid='#{testid}']", **kwargs)
    end

    def find_by_testid(testid, **kwargs)
      page.find("[data-testid='#{testid}']", **kwargs)
    end

    def within_testid(testid, **kwargs, &block)
      page.within("[data-testid='#{testid}']", **kwargs, &block)
    end
  end
end
