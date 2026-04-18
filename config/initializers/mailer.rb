require Rails.root.join("lib/microsoft_graph/delivery")

ActionMailer::Base.add_delivery_method :graph, MicrosoftGraph::Delivery
