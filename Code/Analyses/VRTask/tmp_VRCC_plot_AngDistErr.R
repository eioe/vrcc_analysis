
c_threat <- "#FE5D9F"
c_nonthreat <- "#54426B"
c_neutral <- "#623CEA"
c_systole <- "#F686BD"
c_diastole <- "#F4BBD3"


data_sorted <- data %>%
  group_by(Stimulus, ID) %>%
  dplyr::summarize(AngularErrorDeg = mean(-1 * AngularErrorDeg), 
                   FearObject = first(FearObject)) %>%
  ungroup()

ggplot(data_sorted, aes(x = AngularErrorDeg, y = fct_reorder(Stimulus, .x = AngularErrorDeg, .fun=mean), fill = FearObject)) +
  geom_density_ridges(alpha = 0.9,jittered_points = TRUE, point_alpha=1,point_shape=21, stat = "density_ridges") +
  theme_ridges() +
  theme(legend.position = "none") +
  scale_fill_manual(values = c(c_threat, c_nonthreat)) + 
  geom_vline(xintercept = 0, color = c_neutral)

ggplot(data, aes(x = -1 * AngularErrorDeg, y = fct_reorder(Stimulus, .x = -1 * AngularErrorDeg, .fun=mean), fill = FearObject)) +
  geom_density_ridges() +
  theme_ridges() +
  theme(legend.position = "none") +
  scale_fill_manual(values = c(c_threat, c_nonthreat)) + 
  geom_vline(xintercept = 0, color = c_neutral) +
  coord_cartesian(xlim = c(-10, 10))
  



data_sorted <- data %>%
  group_by(Stimulus, ID) %>%
  dplyr::summarize(DistanceError = mean(DistanceError), 
                   FearObject = first(FearObject)) %>%
  ungroup()

ggplot(data_sorted, aes(x = DistanceError, y = fct_reorder(Stimulus, .x = DistanceError, .fun=mean), fill = FearObject)) +
  geom_density_ridges(alpha = 0.9,jittered_points = TRUE, point_alpha=1,point_shape=21, stat = "density_ridges") +
  theme_ridges() +
  theme(legend.position = "none") +
  geom_vline(xintercept = 0, color = c_neutral) + 
  scale_fill_manual(values = c(c_threat, c_nonthreat)) + 
  coord_flip()


ggplot(data, aes(x = DistanceError, y = fct_reorder(Stimulus, .x = DistanceError, .fun=mean), fill = FearObject)) +
  geom_density_ridges(alpha = 0.9, stat = "density_ridges") +
  theme_ridges() +
  theme(legend.position = "none") +
  geom_vline(xintercept = 0, color = c_neutral) + 
  scale_fill_manual(values = c(c_threat, c_nonthreat)) + 
  coord_flip() +
  xlim(-250, 250)



data %>% group_by(ID, Stimulus) %>% 
  dplyr::summarise(m_ang = mean(AngularErrorDeg), 
                   m_ditst = mean(DistanceError)) -> o

o %>% 
  filter(Stimulus == 'FinalSnake') %>% 
  ggplot(aes(x = m_ang, y = m_ditst)) + geom_point()

