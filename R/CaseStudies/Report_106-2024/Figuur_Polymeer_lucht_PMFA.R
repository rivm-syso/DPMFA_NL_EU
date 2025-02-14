#### Make figure

Figuur_1 <-
  ggplot(polymer_plastics_air, 
         aes(x = reorder(Polymer,Mass_Polymer_t), 
             y = Mass_Polymer_t, fill=Polymer)) +
  geom_violin(fill = "#CA005D") + ##990047
  scale_y_log10(labels = scales::number_format())+
  # geom_text(aes(y=0.001, label = Polymer), vjust = "left")+
  labs(x = "Polymeer", y = "Microplastic emissie naar lucht (ton, log schaal)") +                   # Adjust labels
  coord_flip() + 
  theme_classic() +  
  theme(legend.position="none")

# print(Figuur_1)
